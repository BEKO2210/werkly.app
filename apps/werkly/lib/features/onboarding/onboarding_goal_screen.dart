import 'package:flutter/material.dart';

/// Screen-ID: S-01 — Arch §4 placeholder.
class OnboardingGoalScreen extends StatelessWidget {
  const OnboardingGoalScreen({super.key});

  static const screenId = 'S-01';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding Ziel (S-01)'),
      ),
      body: const Center(
        child: Text(
          'S-01 · Onboarding Ziel',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
