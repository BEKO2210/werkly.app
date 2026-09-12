import 'package:flutter/material.dart';

/// Screen-ID: S-06 — Arch §4 placeholder.
class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  static const screenId = 'S-06';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benachrichtigungen (S-06)'),
      ),
      body: const Center(
        child: Text(
          'S-06 · Benachrichtigungen',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
