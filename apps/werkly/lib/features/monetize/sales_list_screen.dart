import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/monetize/domain/monetize_models.dart';
import 'package:werkly/features/monetize/providers/monetize_providers.dart';
import 'package:werkly/features/monetize/widgets/sale_card.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-54 — Sales list (orders GET) + simulate sale (mock webhook).
class SalesListScreen extends ConsumerWidget {
  const SalesListScreen({super.key});

  static const screenId = ScreenIds.salesList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(monetizeNotifierProvider);
    final isPro = ref.watch(isProProvider);
    final fee = isPro
        ? QuotaPolicy.proPlatformFeeBps
        : QuotaPolicy.freePlatformFeeBps;

    return Scaffold(
      appBar: AppBar(title: const Text('Umsätze')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final state = ref.read(monetizeNotifierProvider).valueOrNull;
          final product = state?.products.where((p) => p.live);
          final tip = state?.tips.where((t) => t.live);
          if (product != null && product.isNotEmpty) {
            final p = product.first;
            await ref.read(monetizeNotifierProvider.notifier).simulateSale(
                  kind: SaleKind.product,
                  amountCents: p.priceCents,
                  offerId: p.id,
                  label: p.name,
                );
          } else if (tip != null && tip.isNotEmpty) {
            final t = tip.first;
            await ref.read(monetizeNotifierProvider.notifier).simulateSale(
                  kind: SaleKind.tip,
                  amountCents: t.suggestedAmountsCents.isEmpty
                      ? 500
                      : t.suggestedAmountsCents.first,
                  offerId: t.id,
                  label: t.label,
                );
          } else {
            await ref.read(monetizeNotifierProvider.notifier).simulateSale();
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mock-Verkauf (orders GET)')),
            );
          }
        },
        icon: const Icon(Icons.add_card_outlined),
        label: const Text('Verkauf simulieren'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Nur Lesen (GET orders). Writes kommen vom Stripe-Webhook. '
                  'Platform-Fee ${fee / 100} % · '
                  'Pro-Abo 9,99 €/Mo ≠ diese Creator-Sales.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: state.sales.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Noch keine Umsätze',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Nach einem Mock-Checkout oder „Verkauf simulieren“ '
                                'erscheinen Beträge hier (de-DE EUR).',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(monetizeNotifierProvider.notifier)
                            .refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: state.sales.length,
                          itemBuilder: (context, i) =>
                              SaleCard(sale: state.sales[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
