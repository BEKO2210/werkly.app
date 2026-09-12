import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/calendar/domain/calendar_post.dart';
import 'package:werkly/features/captions/domain/caption_models.dart';
import 'package:werkly/features/captions/providers/caption_providers.dart';
import 'package:werkly/features/captions/widgets/caption_variant_card.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-21 — Results: ≥3 captions + ≥1 hook, copy / favorite / calendar.
class CaptionResultScreen extends ConsumerStatefulWidget {
  const CaptionResultScreen({super.key, required this.generationId});

  final String generationId;

  static const screenId = ScreenIds.captionResult;

  @override
  ConsumerState<CaptionResultScreen> createState() =>
      _CaptionResultScreenState();
}

class _CaptionResultScreenState extends ConsumerState<CaptionResultScreen> {
  bool _regenBusy = false;
  String? _errorKlartext;

  Future<void> _regenerate(CaptionGeneration previous) async {
    setState(() {
      _regenBusy = true;
      _errorKlartext = null;
    });
    final quota = await ref.read(captionQuotaProvider.future);
    if (!mounted) return;
    if (QuotaPolicy.shouldBlockCaptionGenerate(
      isPro: quota.plan == 'pro',
      usedThisMonth: quota.used,
    )) {
      setState(() => _regenBusy = false);
      context.push(
        '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerCaptions}',
      );
      return;
    }

    final result = await ref
        .read(captionGenerateNotifierProvider.notifier)
        .regenerate(previous);
    if (!mounted) return;
    setState(() => _regenBusy = false);

    if (result.softGated) {
      context.push(
        '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerCaptions}',
      );
      return;
    }
    if (result.error != null) {
      setState(() => _errorKlartext = result.error!.error);
      return;
    }
    if (result.generation != null) {
      // New generation_id — replace route so back goes to home.
      context.pushReplacement(RoutePaths.texteResult(result.generation!.id));
    }
  }

  void _toCalendar(CaptionVariant variant, CaptionGeneration gen) {
    final platforms = <PostPlatform>{};
    final hint = gen.platform;
    if (hint != null && hint != CaptionPlatformHint.neutral) {
      platforms.add(switch (hint) {
        CaptionPlatformHint.ig => PostPlatform.ig,
        CaptionPlatformHint.tiktok => PostPlatform.tiktok,
        CaptionPlatformHint.yt => PostPlatform.youtube,
        CaptionPlatformHint.other => PostPlatform.other,
        CaptionPlatformHint.neutral => PostPlatform.other,
      });
    }
    context.push(
      RoutePaths.planenPost,
      extra: CaptionPrefill(
        captionPrefill: variant.body,
        platformHint: gen.platform,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(captionGenerationProvider(widget.generationId));
    final favsAsync = ref.watch(captionFavoritesProvider);
    final favoriteVariantIds = {
      for (final f in favsAsync.valueOrNull ?? <Favorite>[])
        if (f.sourceVariantId != null) f.sourceVariantId!,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ergebnisse'),
        actions: [
          IconButton(
            tooltip: 'Favoriten',
            onPressed: () => context.push(RoutePaths.texteFavorites),
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
      body: async.when(
        loading: () => const _ShimmerBody(),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('KI gerade nicht erreichbar'),
              TextButton(
                onPressed: () => ref.invalidate(
                  captionGenerationProvider(widget.generationId),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (gen) {
          if (gen == null) {
            return const Center(child: Text('Generation nicht gefunden'));
          }
          final captions = gen.captions;
          final hooks = gen.hooks;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('S-21 · Caption Result', style: TextStyle(fontSize: 12)),
              if (gen.providerNote != null) ...[
                const SizedBox(height: 8),
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(gen.providerNote!, style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
              if (_errorKlartext != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorKlartext!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(
                  onPressed: _regenBusy ? null : () => _regenerate(gen),
                  child: const Text('Retry'),
                ),
              ],
              const SizedBox(height: 12),
              Text('Captions (${captions.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...captions.map(
                (v) => CaptionVariantCard(
                  variant: v,
                  isFavorite: favoriteVariantIds.contains(v.id) || v.isFavorite,
                  onCopy: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kopiert')),
                    );
                  },
                  onFavorite: () {
                    ref
                        .read(captionGenerateNotifierProvider.notifier)
                        .toggleFavorite(v, language: gen.language);
                  },
                  onToCalendar: () => _toCalendar(v, gen),
                ),
              ),
              const SizedBox(height: 8),
              Text('Hooks (${hooks.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...hooks.map(
                (v) => CaptionVariantCard(
                  variant: v,
                  isFavorite: favoriteVariantIds.contains(v.id) || v.isFavorite,
                  onCopy: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kopiert')),
                    );
                  },
                  onFavorite: () {
                    ref
                        .read(captionGenerateNotifierProvider.notifier)
                        .toggleFavorite(v, language: gen.language);
                  },
                  onToCalendar: () => _toCalendar(v, gen),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _regenBusy ? null : () => _regenerate(gen),
                icon: _regenBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Regenerieren'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Regenerieren zählt gegen dein Monatskontingent.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShimmerBody extends StatelessWidget {
  const _ShimmerBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(4, (i) {
        return Container(
          height: 96,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      }),
    );
  }
}
