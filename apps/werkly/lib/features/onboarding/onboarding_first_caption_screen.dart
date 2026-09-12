import 'package:flutter/material.dart';

/// Screen-ID: S-02 — Arch §4 placeholder.
class OnboardingFirstCaptionScreen extends StatelessWidget {
  const OnboardingFirstCaptionScreen({super.key});

  static const screenId = 'S-02';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erste Caption (S-02)'),
      ),
      body: const Center(
        child: Text(
          'S-02 · Erste Caption',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
