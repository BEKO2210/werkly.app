import 'package:flutter/material.dart';

/// Screen-ID: S-60 — Soft paywall stub (9,99 €/Mo + Restore). No store calls.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static const screenId = 'S-60';
  static const proPriceLabel = '9,99 €/Mo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Werkly Pro (S-60)'),
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
            const Text(
              'Mehr Kontingent, Insights und Deals mit Pro.',
              textAlign: TextAlign.center,
            ),
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
          ],
        ),
      ),
    );
  }
}
