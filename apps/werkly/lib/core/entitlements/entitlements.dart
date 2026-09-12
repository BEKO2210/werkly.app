import 'package:flutter_riverpod/flutter_riverpod.dart';

/// RevenueCat entitlement id (locked): `pro`.
abstract final class EntitlementIds {
  static const pro = 'pro';
}

/// Soft stub — always free until RC is wired. No secrets.
final isProProvider = Provider<bool>((ref) => false);

bool get isProStub => false;
