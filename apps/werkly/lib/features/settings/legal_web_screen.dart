import 'package:flutter/material.dart';

/// Screen-ID: S-62 — Arch §4 placeholder.
class LegalWebScreen extends StatelessWidget {
  const LegalWebScreen({super.key, required this.doc});

  final String doc;

  static const screenId = 'S-62';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal (S-62)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'S-62 · Legal',
              textAlign: TextAlign.center,
            ),
            Text('doc: ${doc}'),
          ],
        ),
      ),
    );
  }
}
