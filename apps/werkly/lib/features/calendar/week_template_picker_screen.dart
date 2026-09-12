import 'package:flutter/material.dart';

/// Screen-ID: S-13 — Arch §4 placeholder.
class WeekTemplatePickerScreen extends StatelessWidget {
  const WeekTemplatePickerScreen({super.key});

  static const screenId = 'S-13';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wochen-Vorlagen (S-13)'),
      ),
      body: const Center(
        child: Text(
          'S-13 · Wochen-Vorlagen',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
