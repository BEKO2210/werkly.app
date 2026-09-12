import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:werkly/core/network/connectivity_providers.dart';

/// Offline indicator — banner, not fullscreen block (UI-POLISH).
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, this.forceOffline});

  /// Override for tests; when null, watches [isOfflineProvider].
  final bool? forceOffline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool offline = forceOffline ?? ref.watch(isOfflineProvider);
    if (!offline) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: const SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.cloud_off, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Offline — Änderungen werden synchronisiert',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
