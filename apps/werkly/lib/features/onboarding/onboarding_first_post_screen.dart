import 'package:flutter/material.dart';

/// Screen-ID: S-03 — Arch §4 placeholder.
class OnboardingFirstPostScreen extends StatelessWidget {
  const OnboardingFirstPostScreen({super.key});

  static const screenId = 'S-03';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erster Post (S-03)'),
      ),
      body: const Center(
        child: Text(
          'S-03 · Erster Post',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
