import 'package:flutter/material.dart';

/// Screen-ID: S-22 — Arch §4 placeholder.
class CaptionFavoritesScreen extends StatelessWidget {
  const CaptionFavoritesScreen({super.key});

  static const screenId = 'S-22';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caption Favoriten (S-22)'),
      ),
      body: const Center(
        child: Text(
          'S-22 · Caption Favoriten',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
