import 'package:flutter/material.dart';

/// Screen-ID: S-20 — Arch §4 placeholder.
class CaptionHomeScreen extends StatelessWidget {
  const CaptionHomeScreen({super.key});

  static const screenId = 'S-20';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caption Home (S-20)'),
      ),
      body: const Center(
        child: Text(
          'S-20 · Caption Home',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
