import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:werkly/features/hub/domain/hub_models.dart';
import 'package:werkly/features/hub/domain/public_hub_api.dart';
import 'package:werkly/features/hub/providers/hub_providers.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-33 — Flutter mock of public landing via GET public-hub?slug=.
class HubPreviewScreen extends ConsumerWidget {
  const HubPreviewScreen({super.key});

  static const screenId = ScreenIds.hubPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHub = ref.watch(hubEditorNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub-Vorschau'),
      ),
      body: asyncHub.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (hub) => FutureBuilder<PublicHubDto>(
          future: ref.read(publicHubClientProvider).getPublicHub(slug: hub.slug),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              final err = snap.error;
              if (err is HubApiError && err.isNotFound) {
                return const Center(child: Text('404 · Hub nicht öffentlich'));
              }
              return Center(child: Text('Fehler: ${snap.error}'));
            }
            final dto = snap.data!;
            return _PublicLandingMock(
              dto: dto,
              onLinkTap: (linkId) async {
                try {
                  await ref.read(trackHubClickClientProvider).track(
                        TrackHubClickRequest(hubLinkId: linkId),
                      );
                  ref.invalidate(hubAnalyticsProvider);
                } catch (_) {
                  // Soft: preview still usable if track fails.
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _PublicLandingMock extends StatelessWidget {
  const _PublicLandingMock({
    required this.dto,
    required this.onLinkTap,
  });

  final PublicHubDto dto;
  final Future<void> Function(String linkId) onLinkTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = dto.displayName;
    return Container(
      color: scheme.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'W',
                style: TextStyle(
                  fontSize: 36,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (dto.bio != null && dto.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              dto.bio!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 28),
          ...dto.links.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onLinkTap(link.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _iconFor(link.linkType),
                          color: scheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            link.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: scheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (dto.links.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Noch keine Links',
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 32),
          if (dto.showBranding)
            Column(
              children: [
                Divider(color: scheme.outlineVariant),
                const SizedBox(height: 12),
                Text(
                  'Powered by Werkly',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                ),
                Text(
                  'werkly.app/h/${dto.slug}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            )
          else
            Text(
              'werkly.app/h/${dto.slug}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 24),
          Text(
            'S-33 · GET public-hub?slug= · POST track-hub-click',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  IconData _iconFor(HubLinkType t) => switch (t) {
        HubLinkType.url => Icons.link,
        HubLinkType.social => Icons.alternate_email,
        HubLinkType.mediaKit => Icons.description_outlined,
        HubLinkType.product => Icons.shopping_bag_outlined,
        HubLinkType.tip => Icons.favorite_outline,
      };
}
