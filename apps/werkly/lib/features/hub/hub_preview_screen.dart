import 'package:flutter/material.dart';

/// Screen-ID: S-33 — Arch §4 placeholder.
class HubPreviewScreen extends StatelessWidget {
  const HubPreviewScreen({super.key});

  static const screenId = 'S-33';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub Preview (S-33)'),
      ),
      body: const Center(
        child: Text(
          'S-33 · Hub Preview',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
