import 'package:flutter/material.dart';

/// Screen-ID: S-31 — Arch §4 placeholder.
class HubLinkEditorScreen extends StatelessWidget {
  const HubLinkEditorScreen({super.key, this.id});

  final String? id;

  static const screenId = 'S-31';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub Link Editor (S-31)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'S-31 · Hub Link Editor',
              textAlign: TextAlign.center,
            ),
            if (id != null) Text('id: ${id}'),
          ],
        ),
      ),
    );
  }
}
