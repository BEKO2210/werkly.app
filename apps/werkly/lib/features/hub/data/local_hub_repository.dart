import 'dart:math';

import 'package:uuid/uuid.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/hub/data/hub_memory_store.dart';
import 'package:werkly/features/hub/domain/hub_models.dart';
import 'package:werkly/features/hub/domain/hub_repository.dart';
import 'package:werkly/features/hub/domain/hub_slug.dart';
import 'package:werkly/features/hub/domain/hub_validation.dart';

/// Result of branding/slug mutate attempt (soft gate).
class HubGateResult {
  const HubGateResult._({this.hub, this.softGated = false, this.trigger});

  final Hub? hub;
  final bool softGated;
  final String? trigger;

  bool get ok => hub != null && !softGated;

  factory HubGateResult.ok(Hub hub) => HubGateResult._(hub: hub);

  factory HubGateResult.paywall() => HubGateResult._(
        softGated: true,
        trigger: QuotaPolicy.paywallTriggerHubBranding,
      );
}

class LocalHubRepository implements HubRepository {
  LocalHubRepository({
    required HubMemoryStore store,
    Uuid? uuid,
    String publicHost = HubSlug.defaultPublicHost,
    String defaultUserId = 'local-user',
  })  : _store = store,
        _uuid = uuid ?? const Uuid(),
        publicHost = publicHost,
        defaultUserId = defaultUserId;

  final HubMemoryStore _store;
  final Uuid _uuid;
  final String publicHost;
  final String defaultUserId;

  HubMemoryStore get store => _store;

  @override
  Future<Hub?> getHubForUser(String userId) async {
    final hub = await _store.getHub();
    if (hub == null) return null;
    if (hub.userId != userId) return null;
    return hub;
  }

  @override
  Future<Hub?> getHubBySlug(String slug) => _store.bySlug(slug);

  @override
  Future<Hub> getOrCreateHub({
    required String userId,
    String displayName = 'Mein Hub',
  }) async {
    final existing = await getHubForUser(userId);
    if (existing != null) return existing;

    // Free: one hub — if any hub exists for another user id, still block second
    // for same user; scaffold uses single local user.
    final any = await _store.getHub();
    if (any != null && any.userId == userId) return any;

    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final taken = await _store.takenSlugs();
    final slug = HubSlug.uniqueSlug(displayName, taken: taken);
    final hub = Hub(
      id: id,
      clientId: id,
      userId: userId,
      displayName: displayName,
      bio: '',
      slug: slug,
      showBranding: true,
      isPublic: true,
      links: const [],
      createdAt: now,
      updatedAt: now,
    );
    return _store.upsertHub(hub);
  }

  /// Free cannot create a second hub.
  Future<HubGateResult> createHubIfAllowed({
    required String userId,
    required bool isPro,
    String displayName = 'Mein Hub',
  }) async {
    final existing = await getHubForUser(userId);
    if (existing != null) return HubGateResult.ok(existing);
    final count = (await _store.getHub()) != null ? 1 : 0;
    if (HubValidation.wouldExceedFreeHubLimit(
      isPro: isPro,
      existingHubCountForUser: count,
    )) {
      return HubGateResult.paywall();
    }
    final hub = await getOrCreateHub(userId: userId, displayName: displayName);
    return HubGateResult.ok(hub);
  }

  @override
  Future<Hub> saveHub(Hub hub) async {
    final updated = hub.copyWith(updatedAt: DateTime.now().toUtc());
    return _store.upsertHub(updated);
  }

  Future<Hub> updateProfile({
    required Hub hub,
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool clearAvatar = false,
    bool regenerateSlugFromName = false,
  }) async {
    var next = hub.copyWith(
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
      clearAvatar: clearAvatar,
      updatedAt: DateTime.now().toUtc(),
    );
    if (regenerateSlugFromName && displayName != null) {
      final taken = await _store.takenSlugs();
      next = next.copyWith(
        slug: HubSlug.uniqueSlug(
          displayName,
          taken: taken,
          ignoreSlug: hub.slug,
        ),
      );
    }
    return saveHub(next);
  }

  /// Pro-only: custom slug. Free → soft gate.
  Future<HubGateResult> setCustomSlug({
    required Hub hub,
    required String rawSlug,
    required bool isPro,
  }) async {
    // Any explicit custom edit while Free is gated.
    if (!isPro) {
      return HubGateResult.paywall();
    }
    final taken = await _store.takenSlugs();
    final slug = HubSlug.uniqueSlug(
      rawSlug,
      taken: taken,
      ignoreSlug: hub.slug,
    );
    final saved = await saveHub(hub.copyWith(slug: slug));
    return HubGateResult.ok(saved);
  }

  /// Free must keep showBranding true; toggling off → paywall.
  Future<HubGateResult> setShowBranding({
    required Hub hub,
    required bool showBranding,
    required bool isPro,
  }) async {
    if (!isPro && !showBranding) {
      return HubGateResult.paywall();
    }
    final saved = await saveHub(hub.copyWith(showBranding: showBranding));
    return HubGateResult.ok(saved);
  }

  @override
  Future<HubLink> upsertLink(HubLink link) async {
    final hub = await _store.getHub();
    if (hub == null || hub.id != link.hubId) {
      throw StateError('Hub not found for link');
    }
    final links = List<HubLink>.from(hub.links);
    final idx = links.indexWhere((l) => l.id == link.id);
    if (idx >= 0) {
      links[idx] = link;
    } else {
      links.add(link);
    }
    await saveHub(hub.copyWith(links: links));
    return link;
  }

  Future<HubLink> addLink({
    required String hubId,
    required HubLinkType type,
    required String label,
    String? url,
    String? refId,
  }) async {
    final hub = await _store.getHub();
    if (hub == null || hub.id != hubId) {
      throw StateError('Hub not found');
    }
    final order = hub.links.isEmpty
        ? 0
        : hub.links.map((l) => l.sortOrder).reduce(max) + 1;
    final link = HubLink(
      id: _uuid.v4(),
      hubId: hubId,
      type: type,
      label: label.trim(),
      url: url?.trim().isEmpty == true ? null : url?.trim(),
      sortOrder: order,
      refId: refId,
    );
    await upsertLink(link);
    return link;
  }

  @override
  Future<void> deleteLink(String linkId) async {
    final hub = await _store.getHub();
    if (hub == null) return;
    final links = hub.links.where((l) => l.id != linkId).toList();
    await saveHub(hub.copyWith(links: links));
  }

  @override
  Future<Hub> reorderLinks(String hubId, List<String> orderedLinkIds) async {
    final hub = await _store.getHub();
    if (hub == null || hub.id != hubId) {
      throw StateError('Hub not found');
    }
    final byId = {for (final l in hub.links) l.id: l};
    final reordered = <HubLink>[];
    for (var i = 0; i < orderedLinkIds.length; i++) {
      final id = orderedLinkIds[i];
      final existing = byId.remove(id);
      if (existing != null) {
        reordered.add(existing.copyWith(sortOrder: i));
      }
    }
    // Append any leftover
    for (final left in byId.values) {
      reordered.add(left.copyWith(sortOrder: reordered.length));
    }
    return saveHub(hub.copyWith(links: reordered));
  }

  @override
  Future<MediaKit?> getMediaKitForHub(String hubId) async {
    final kit = await _store.getKit();
    if (kit == null || kit.hubId != hubId) return null;
    return kit;
  }

  @override
  Future<MediaKit> saveMediaKit(MediaKit kit) async {
    var next = kit.copyWith(updatedAt: DateTime.now().toUtc());
    if (next.publicSlug == null || next.publicSlug!.isEmpty) {
      final taken = await _store.takenSlugs();
      final base = 'kit-${HubSlug.slugify(next.pitch.isNotEmpty ? next.pitch : 'media')}';
      next = next.copyWith(
        publicSlug: HubSlug.uniqueSlug(base, taken: taken),
      );
    }
    // Cap example links 1–3
    if (next.exampleLinks.length > 3) {
      next = next.copyWith(
        exampleLinks: next.exampleLinks.take(3).toList(),
      );
    }
    return _store.upsertKit(next);
  }

  Future<MediaKit> getOrCreateMediaKit({
    required Hub hub,
  }) async {
    final existing = await getMediaKitForHub(hub.id);
    if (existing != null) return existing;
    final id = _uuid.v4();
    final kit = MediaKit(
      id: id,
      clientId: id,
      userId: hub.userId,
      hubId: hub.id,
      niches: const [],
      platforms: const [],
      exampleLinks: const [],
      pitch: '',
      updatedAt: DateTime.now().toUtc(),
    );
    return saveMediaKit(kit);
  }

  @override
  Future<List<HubLinkClickStats>> linkStats(String hubId) async {
    // Prefer recorded track-hub-click counts; otherwise zeros (Should).
    return _store.statsFor(hubId);
  }

  @override
  String shareUrlFor(Hub hub) =>
      HubSlug.buildPublicUrl(hub.slug, host: publicHost);

  @override
  String mediaKitShareUrl(MediaKit kit) {
    final slug = kit.publicSlug ?? kit.id;
    return HubSlug.buildMediaKitUrl(slug, host: publicHost);
  }

  bool isShareReady(Hub hub) => HubValidation.isShareReady(hub);
}
