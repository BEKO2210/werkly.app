import 'package:flutter/material.dart';

/// Screen-ID: S-52 — Arch §4 placeholder.
class ProductEditorScreen extends StatelessWidget {
  const ProductEditorScreen({super.key, this.id});

  final String? id;

  static const screenId = 'S-52';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produkt Editor (S-52)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'S-52 · Produkt Editor',
              textAlign: TextAlign.center,
            ),
            if (id != null) Text('id: ${id}'),
          ],
        ),
      ),
    );
  }
}
