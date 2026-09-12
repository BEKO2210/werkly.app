import 'package:flutter/material.dart';

/// Screen-ID: S-05 — Arch §4 placeholder.
class OnboardingStripeOptionalScreen extends StatelessWidget {
  const OnboardingStripeOptionalScreen({super.key});

  static const screenId = 'S-05';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe optional (S-05)'),
      ),
      body: const Center(
        child: Text(
          'S-05 · Stripe optional',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
