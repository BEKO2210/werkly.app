import 'package:flutter/material.dart';

/// Screen-ID: S-04 — Arch §4 placeholder.
class OnboardingHubTeaserScreen extends StatelessWidget {
  const OnboardingHubTeaserScreen({super.key});

  static const screenId = 'S-04';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub Teaser (S-04)'),
      ),
      body: const Center(
        child: Text(
          'S-04 · Hub Teaser',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
