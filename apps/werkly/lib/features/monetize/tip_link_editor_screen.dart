import 'package:flutter/material.dart';

/// Screen-ID: S-53 — Arch §4 placeholder.
class TipLinkEditorScreen extends StatelessWidget {
  const TipLinkEditorScreen({super.key, this.id});

  final String? id;

  static const screenId = 'S-53';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tip Link Editor (S-53)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'S-53 · Tip Link Editor',
              textAlign: TextAlign.center,
            ),
            if (id != null) Text('id: ${id}'),
          ],
        ),
      ),
    );
  }
}
