import 'package:flutter/material.dart';

/// Offline indicator stub (connectivity_plus to be wired).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.isOffline = false});

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Offline — Änderungen werden später synchronisiert.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
