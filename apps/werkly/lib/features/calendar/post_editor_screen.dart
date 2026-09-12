import 'package:flutter/material.dart';

/// Screen-ID: S-11 — Arch §4 placeholder.
class PostEditorScreen extends StatelessWidget {
  const PostEditorScreen({super.key, this.id});

  final String? id;

  static const screenId = 'S-11';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Editor (S-11)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'S-11 · Post Editor',
              textAlign: TextAlign.center,
            ),
            if (id != null) Text('id: ${id}'),
          ],
        ),
      ),
    );
  }
}
