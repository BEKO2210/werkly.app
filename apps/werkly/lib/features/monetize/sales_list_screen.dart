import 'package:flutter/material.dart';

/// Screen-ID: S-54 — Arch §4 placeholder.
class SalesListScreen extends StatelessWidget {
  const SalesListScreen({super.key});

  static const screenId = 'S-54';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Liste (S-54)'),
      ),
      body: const Center(
        child: Text(
          'S-54 · Sales Liste',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
