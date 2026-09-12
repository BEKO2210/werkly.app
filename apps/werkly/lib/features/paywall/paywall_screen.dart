import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/router/screen_ids.dart';
import 'package:werkly/ui/theme/app_spacing.dart';

/// Screen-ID: S-60 — Soft paywall: benefits → 9,99 €/Mo → Weiter mit Free.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static const screenId = ScreenIds.paywall;
  static const proPriceLabel = '9,99 €/Mo';

  @override
  Widget build(BuildContext context) {
    final trigger =
        GoRouterState.of(context).uri.queryParameters['trigger'] ?? '';
    final contextLine = switch (trigger) {
      QuotaPolicy.paywallTriggerCalendar =>
        'Limit: mehr als 10 Posts / ISO-Woche',
      QuotaPolicy.paywallTriggerTemplates => 'Wochen-Vorlagen sind Pro',
      QuotaPolicy.paywallTriggerCaptions => 'Caption-Limit erreicht (10/Monat)',
      QuotaPolicy.paywallTriggerHubBranding =>
        'Custom Slug & Branding aus — Pro',
      QuotaPolicy.paywallTriggerDeals => 'Max. 5 offene Deals im Free',
      QuotaPolicy.paywallTriggerDealExport => 'CSV-Export ist Pro',
      QuotaPolicy.paywallTriggerStripeProducts =>
        'Free: Tip oder 1 Produkt',
      _ => null,
    };

    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Werkly Pro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Schließen',
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Unbegrenzte Captions & Deals',
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Plane ohne Wochen-Limit, generiere Captions ohne Stopp, '
              'tracke alle Brand-Deals und schalte Hub-Branding frei.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (contextLine != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Card(
                color: scheme.primaryContainer,
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Text(
                    contextLine,
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            const _Benefit(icon: Icons.auto_awesome, label: 'Captions ohne Monats-Cap'),
            const _Benefit(icon: Icons.handshake_outlined, label: 'Unbegrenzte offene Deals'),
            const _Benefit(icon: Icons.calendar_month, label: 'Kalender ohne Wochen-Limit'),
            const _Benefit(icon: Icons.hub_outlined, label: 'Custom Slug & Branding aus'),
            const Spacer(),
            FilledButton(
              onPressed: () {
                // Soft paywall stub — RevenueCat purchase later.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kauf folgt (RevenueCat) · $proPriceLabel'),
                  ),
                );
              },
              child: const Text('Pro starten · $proPriceLabel'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wiederherstellen folgt (Play)')),
                );
              },
              child: const Text('Käufe wiederherstellen'),
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Weiter mit Free'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
