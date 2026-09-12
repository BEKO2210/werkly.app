import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-05 — Optional Stripe; skip default. Usable path to S-51.
class OnboardingStripeOptionalScreen extends StatelessWidget {
  const OnboardingStripeOptionalScreen({super.key});

  static const screenId = ScreenIds.onboardingStripeOptional;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Später verkaufen')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Stripe Connect ist optional. '
              'Du kannst Tip oder 1 Produkt verkaufen, sobald Connect aktiv ist.',
            ),
            const SizedBox(height: 12),
            Text(
              'Werkly Pro (9,99 €/Mo) ist dein App-Abo — '
              'unabhängig von Creator-Verkäufen über Stripe.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.go(RoutePaths.monetizeConnect),
              child: const Text('Stripe jetzt verbinden'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(RoutePaths.planen),
              child: const Text('Überspringen — später unter Mehr → Verkaufen'),
            ),
          ],
        ),
      ),
    );
  }
}
