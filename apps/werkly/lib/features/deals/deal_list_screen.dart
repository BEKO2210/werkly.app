import 'package:flutter/material.dart';

/// Screen-ID: S-40 — Arch §4 placeholder.
class DealListScreen extends StatelessWidget {
  const DealListScreen({super.key});

  static const screenId = 'S-40';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deal Liste (S-40)'),
      ),
      body: const Center(
        child: Text(
          'S-40 · Deal Liste',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
