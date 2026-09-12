import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-60 — Soft paywall stub (9,99 €/Mo + Restore). No store calls.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static const screenId = ScreenIds.paywall;
  static const proPriceLabel = '9,99 €/Mo';

  @override
  Widget build(BuildContext context) {
    final trigger =
        GoRouterState.of(context).uri.queryParameters['trigger'] ?? '';
    final headline = switch (trigger) {
      QuotaPolicy.paywallTriggerCalendar =>
        'Mehr als 10 Posts/ISO-Woche — mit Pro unbegrenzt planen',
      QuotaPolicy.paywallTriggerTemplates =>
        'Wochen-Vorlagen sind Teil von Werkly Pro',
      QuotaPolicy.paywallTriggerCaptions =>
        '10 Captions/Monat aufgebraucht — mit Pro weiter generieren (DE/EN)',
      QuotaPolicy.paywallTriggerHubBranding =>
        'Custom Slug & Branding aus — mit Pro brand-ready Hub (9,99 €/Mo)',
      QuotaPolicy.paywallTriggerDeals =>
        'Max. 5 offene Deals im Free — mit Pro unbegrenzt tracken',
      QuotaPolicy.paywallTriggerDealExport =>
        'CSV-Export ist Teil von Werkly Pro',
      QuotaPolicy.paywallTriggerStripeProducts =>
        'Mehr Produkte verkaufen mit Pro — Free: Tip oder 1 Produkt',
      _ => 'Mehr Kontingent, Insights und Deals mit Pro.',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Werkly Pro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'S-60 · Werkly Pro',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(headline, textAlign: TextAlign.center),
            if (trigger.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'trigger=$trigger',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                // Soft paywall stub — no purchases_flutter purchase call yet.
              },
              child: const Text('Pro starten · 9,99 €/Mo'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Restore purchases stub.
              },
              child: const Text('Käufe wiederherstellen'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Weiter im Free-Modus (Inhalt lesbar)'),
            ),
          ],
        ),
      ),
    );
  }
}
