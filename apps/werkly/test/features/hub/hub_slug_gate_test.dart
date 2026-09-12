import 'package:flutter_test/flutter_test.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/hub/data/hub_memory_store.dart';
import 'package:werkly/features/hub/data/local_hub_repository.dart';
import 'package:werkly/features/hub/data/public_hub_client.dart';
import 'package:werkly/features/hub/data/track_hub_click_client.dart';
import 'package:werkly/features/hub/domain/public_hub_api.dart';
import 'package:werkly/features/hub/domain/hub_models.dart';
import 'package:werkly/features/hub/domain/hub_slug.dart';
import 'package:werkly/features/hub/domain/hub_validation.dart';

void main() {
  group('HubSlug.slugify', () {
    test('folds umlauts and strips junk', () {
      expect(HubSlug.slugify('Belkis Aslani'), 'belkis-aslani');
      expect(HubSlug.slugify('Über-Cool!!'), 'ueber-cool');
      expect(HubSlug.slugify('  '), 'hub');
      expect(HubSlug.slugify('ÄÖÜß'), 'aeoeuess');
    });

    test('uniqueSlug appends suffix', () {
      final taken = {'belkis', 'belkis-2'};
      expect(
        HubSlug.uniqueSlug('Belkis', taken: taken),
        'belkis-3',
      );
      expect(
        HubSlug.uniqueSlug('Belkis', taken: taken, ignoreSlug: 'belkis'),
        'belkis',
      );
    });

    test('public URL pattern', () {
      expect(
        HubSlug.buildPublicUrl('my-hub'),
        'https://werkly.app/h/my-hub',
      );
    });
  });

  group('share ready helper', () {
    test('requires at least one enabled labeled link', () {
      final empty = Hub(
        id: '1',
        clientId: '1',
        userId: 'u',
        displayName: 'Test',
        slug: 'test',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      expect(isHubShareReady(empty), isFalse);

      final withLink = empty.copyWith(
        links: [
          const HubLink(
            id: 'l1',
            hubId: '1',
            type: HubLinkType.url,
            label: 'Instagram',
            url: 'https://instagram.com/x',
            sortOrder: 0,
          ),
        ],
      );
      expect(isHubShareReady(withLink), isTrue);

      final blankLabel = empty.copyWith(
        links: [
          const HubLink(
            id: 'l1',
            hubId: '1',
            type: HubLinkType.url,
            label: '  ',
            sortOrder: 0,
          ),
        ],
      );
      expect(isHubShareReady(blankLabel), isFalse);
    });
  });

  group('one-hub free rule', () {
    test('Free blocks second hub; Pro allows', () {
      expect(
        HubValidation.wouldExceedFreeHubLimit(
          isPro: false,
          existingHubCountForUser: 0,
        ),
        isFalse,
      );
      expect(
        HubValidation.wouldExceedFreeHubLimit(
          isPro: false,
          existingHubCountForUser: 1,
        ),
        isTrue,
      );
      expect(
        HubValidation.wouldExceedFreeHubLimit(
          isPro: true,
          existingHubCountForUser: 1,
        ),
        isFalse,
      );
      expect(QuotaPolicy.freeHubLimit, 1);
    });
  });

  group('branding soft gate', () {
    test('Free gates branding off + custom slug', () {
      expect(
        shouldSoftGateHubBrandingOrSlug(
          wantsBrandingOff: true,
          wantsCustomSlug: false,
        ),
        isTrue,
      );
      expect(
        shouldSoftGateHubBrandingOrSlug(
          wantsBrandingOff: false,
          wantsCustomSlug: true,
        ),
        isTrue,
      );
      expect(
        shouldSoftGateHubBrandingOrSlug(
          wantsBrandingOff: false,
          wantsCustomSlug: false,
        ),
        isFalse,
      );
      expect(
        shouldSoftGateHubBrandingOrSlug(
          wantsBrandingOff: true,
          wantsCustomSlug: true,
          isPro: true,
        ),
        isFalse,
      );
      expect(
        QuotaPolicy.paywallTriggerHubBranding,
        'limit_hub_branding',
      );
    });
  });

  group('LocalHubRepository CRUD + gates', () {
    late HubMemoryStore store;
    late LocalHubRepository repo;

    setUp(() {
      store = HubMemoryStore();
      repo = LocalHubRepository(store: store);
    });

    test('getOrCreate + add link + share URL', () async {
      final hub = await repo.getOrCreateHub(
        userId: 'local-user',
        displayName: 'Belkis Hub',
      );
      expect(hub.slug, 'belkis-hub');
      expect(hub.showBranding, isTrue);

      await repo.addLink(
        hubId: hub.id,
        type: HubLinkType.social,
        label: 'IG',
        url: 'https://instagram.com/belkis',
      );
      final refreshed = await repo.getHubForUser('local-user');
      expect(refreshed!.links, hasLength(1));
      expect(repo.isShareReady(refreshed), isTrue);
      expect(
        repo.shareUrlFor(refreshed),
        'https://werkly.app/h/belkis-hub',
      );

      // Same user → same hub (free one-hub)
      final again = await repo.getOrCreateHub(userId: 'local-user');
      expect(again.id, hub.id);
    });

    test('Free branding off → paywall; Pro ok', () async {
      final hub = await repo.getOrCreateHub(userId: 'u1');
      final gated = await repo.setShowBranding(
        hub: hub,
        showBranding: false,
        isPro: false,
      );
      expect(gated.softGated, isTrue);
      expect(gated.trigger, 'limit_hub_branding');

      final ok = await repo.setShowBranding(
        hub: hub,
        showBranding: false,
        isPro: true,
      );
      expect(ok.ok, isTrue);
      expect(ok.hub!.showBranding, isFalse);
    });

    test('Free custom slug → paywall; Pro sets slug', () async {
      final hub = await repo.getOrCreateHub(
        userId: 'u2',
        displayName: 'Creator',
      );
      final gated = await repo.setCustomSlug(
        hub: hub,
        rawSlug: 'brand-ready',
        isPro: false,
      );
      expect(gated.softGated, isTrue);

      final ok = await repo.setCustomSlug(
        hub: hub,
        rawSlug: 'Brand Ready!',
        isPro: true,
      );
      expect(ok.hub!.slug, 'brand-ready');
    });

    test('media kit save + public-hub OpenAPI shape', () async {
      final hub = await repo.getOrCreateHub(userId: 'u3', displayName: 'Kit User');
      final kit = await repo.getOrCreateMediaKit(hub: hub);
      final saved = await repo.saveMediaKit(
        kit.copyWith(
          niches: const ['Beauty', 'Lifestyle'],
          pitch: 'Collabs welcome',
          exampleLinks: const ['https://a.example', 'https://b.example'],
        ),
      );
      expect(saved.publicSlug, isNotNull);
      expect(saved.niches, hasLength(2));

      final client = PublicHubClient(store: store);
      final dto = await client.getPublicHub(slug: hub.slug);
      expect(dto.slug, hub.slug);
      expect(dto.displayName, 'Kit User');
      expect(dto.showBranding, isTrue);
      expect(dto.mediaKit, isNotNull);
      final json = dto.toJson();
      expect(json.keys, containsAll(['slug', 'display_name', 'links', 'show_branding']));
    });

    test('public-hub 404 for unknown slug', () async {
      final client = PublicHubClient(store: store);
      await expectLater(
        client.getPublicHub(slug: 'missing'),
        throwsA(isA<HubApiError>().having((e) => e.isNotFound, '404', isTrue)),
      );
    });

    test('track-hub-click local mock increments analytics', () async {
      final hub = await repo.getOrCreateHub(userId: 'u4', displayName: 'Clicks');
      final link = await repo.addLink(
        hubId: hub.id,
        type: HubLinkType.url,
        label: 'Shop',
        url: 'https://example.com',
      );
      final tracker = TrackHubClickClient(store: store);
      await tracker.track(TrackHubClickRequest(hubLinkId: link.id));
      await tracker.track(TrackHubClickRequest(hubLinkId: link.id));
      final stats = await repo.linkStats(hub.id);
      expect(stats.single.clicks7d, 2);
      expect(stats.single.clicks30d, 2);

      await expectLater(
        tracker.track(const TrackHubClickRequest(hubLinkId: 'nope')),
        throwsA(isA<HubApiError>()),
      );
    });

    test('PublicHubDto matches asset mock required keys', () async {
      // mirrors assets/contracts/mocks/public-hub-200.json
      const sample = {
        'slug': 'belkis-hub',
        'display_name': 'Belkis Hub',
        'bio': 'Creator',
        'avatar_url': null,
        'show_branding': true,
        'links': [
          {
            'id': '00000000-0000-4000-8000-0000000000a1',
            'type': 'social',
            'title': 'Instagram',
            'url': 'https://instagram.com/belkis',
          }
        ],
      };
      final dto = PublicHubDto.fromJson(sample);
      expect(dto.showBranding, isTrue);
      expect(dto.links.single.title, 'Instagram');
      expect(dto.links.single.type, 'social');
    });
  });
}
