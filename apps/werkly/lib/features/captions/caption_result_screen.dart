import 'package:flutter/material.dart';

/// Screen-ID: S-21 — Arch §4 placeholder.
class CaptionResultScreen extends StatelessWidget {
  const CaptionResultScreen({super.key, required this.generationId});

  final String generationId;

  static const screenId = 'S-21';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caption Result (S-21)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'S-21 · Caption Result',
              textAlign: TextAlign.center,
            ),
            Text('generationId: ${generationId}'),
          ],
        ),
      ),
    );
  }
}
