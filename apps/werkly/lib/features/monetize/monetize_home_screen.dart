import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/monetize/providers/monetize_providers.dart';
import 'package:werkly/features/monetize/widgets/connect_status_card.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';
import 'package:werkly/ui/widgets/quota_banner.dart';

/// Screen-ID: S-50 — Monetize home: Connect card, product/tip/sales CTAs.
/// RC Pro-Abo ≠ Stripe Creator-Sales (copy separated).
class MonetizeHomeScreen extends ConsumerWidget {
  const MonetizeHomeScreen({super.key});

  static const screenId = ScreenIds.monetizeHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(monetizeNotifierProvider);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verkaufen')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              QuotaBanner(
                used: state.offerCount,
                limit: isPro
                    ? QuotaPolicy.proLiveProducts
                    : QuotaPolicy.freeLiveOffers,
                label: 'Angebote (Tip oder Produkt)',
                trigger: QuotaPolicy.paywallTriggerStripeProducts,
              ),
              const SizedBox(height: 8),
              ConnectStatusCard(
                status: state.connectStatus,
                onTap: () => context.push(RoutePaths.monetizeConnect),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Dein Pro-Abo (9,99 €/Mo über Play / RevenueCat) ist '
                    'unabhängig von Creator-Verkäufen über Stripe. '
                    'Abo ≠ Umsatz.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Free: Tip oder 1 Produkt · Pro: Tip + bis 10 Produkte. '
                'Platform-Fee ${isPro ? '5' : '10'} % (plan_limits). '
                'Steuern ggf. selbst abführen.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Digitales Produkt'),
                subtitle: Text(
                  state.products.isEmpty
                      ? 'Name, Preis EUR, Unlock-Link'
                      : '${state.products.length} Produkt(e)'
                          '${state.liveProductCount > 0 ? ' · ${state.liveProductCount} live' : ''}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (state.products.isEmpty) {
                    context.push(RoutePaths.monetizeProduct);
                  } else {
                    context.push(
                      RoutePaths.monetizeProductId(state.products.first.id),
                    );
                  }
                },
              ),
              if (state.products.length > 1)
                ...state.products.skip(1).map(
                      (p) => ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text(p.name),
                        subtitle: Text(p.live ? 'Live' : 'Entwurf'),
                        onTap: () =>
                            context.push(RoutePaths.monetizeProductId(p.id)),
                      ),
                    ),
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('Tip-Link'),
                subtitle: Text(
                  state.tips.isEmpty
                      ? 'Betragsvorschläge 3 / 5 / 10 €'
                      : '${state.tips.first.label}'
                          '${state.hasLiveTip ? ' · live' : ''}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (state.tips.isEmpty) {
                    context.push(RoutePaths.monetizeTip);
                  } else {
                    context.push(RoutePaths.monetizeTipId(state.tips.first.id));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Umsätze'),
                subtitle: Text(
                  state.sales.isEmpty
                      ? 'Noch keine Verkäufe'
                      : '${state.sales.length} Einträge (orders GET)',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.monetizeSales),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  if (!state.connectStatus.isActive) {
                    context.push(RoutePaths.monetizeConnect);
                    return;
                  }
                  if (!isPro && state.products.isNotEmpty) {
                    context.push(
                      '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerStripeProducts}',
                    );
                    return;
                  }
                  context.push(RoutePaths.monetizeProduct);
                },
                icon: const Icon(Icons.add),
                label: const Text('Produkt anlegen'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  if (!state.connectStatus.isActive) {
                    context.push(RoutePaths.monetizeConnect);
                    return;
                  }
                  context.push(RoutePaths.monetizeTip);
                },
                icon: const Icon(Icons.favorite_outline),
                label: const Text('Tip-Link anlegen'),
              ),
            ],
          );
        },
      ),
    );
  }
}
