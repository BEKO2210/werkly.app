import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/features/captions/domain/caption_models.dart';
import 'package:werkly/features/captions/providers/caption_providers.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-22 — Favorites list; copy / In Kalender.
class CaptionFavoritesScreen extends ConsumerWidget {
  const CaptionFavoritesScreen({super.key});

  static const screenId = ScreenIds.captionFavorites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(captionFavoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoriten'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (favs) {
          if (favs.isEmpty) {
            return const Center(
              child: Text('Noch keine Favoriten — speichere Varianten in S-21.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final f = favs[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(
                        label: Text(f.kind == CaptionKind.hook ? 'Hook' : 'Caption'),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(f.body),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: f.body));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kopiert')),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Kopieren'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              context.push(
                                RoutePaths.planenPost,
                                extra: CaptionPrefill(captionPrefill: f.body),
                              );
                            },
                            icon: const Icon(Icons.event, size: 18),
                            label: const Text('In Kalender'),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Entfernen',
                            onPressed: () async {
                              await ref
                                  .read(captionRepositoryProvider)
                                  .removeFavorite(f.id);
                              ref.invalidate(captionFavoritesProvider);
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
