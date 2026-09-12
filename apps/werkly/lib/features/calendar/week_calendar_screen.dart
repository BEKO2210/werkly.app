import 'package:flutter/material.dart';

/// Screen-ID: S-10 — Arch §4 placeholder.
class WeekCalendarScreen extends StatelessWidget {
  const WeekCalendarScreen({super.key});

  static const screenId = 'S-10';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wochenkalender (S-10)'),
      ),
      body: const Center(
        child: Text(
          'S-10 · Wochenkalender',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
