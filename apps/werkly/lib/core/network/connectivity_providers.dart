import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True when any non-none connectivity result is present.
final isOnlineProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return results.any((e) => e != ConnectivityResult.none);
  });
});

/// Sync snapshot; defaults to online when stream not ready / plugin missing.
final isOfflineProvider = Provider<bool>((ref) {
  final async = ref.watch(isOnlineProvider);
  return async.maybeWhen(
    data: (online) => !online,
    orElse: () => false,
  );
});
