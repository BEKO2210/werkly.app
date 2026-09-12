/// Supabase stub — no URL/anon key in scaffold (no secrets).
class WerklySupabase {
  WerklySupabase._();

  static bool get isInitialized => _initialized;
  static bool _initialized = false;

  /// True only after real `supabase_flutter.initialize` with URL+anon key.
  /// Scaffold stays false → sync keeps rows `syncPending`.
  static bool get isConfigured => _configured;
  static bool _configured = false;

  /// Call from bootstrap with env-injected values later.
  static Future<void> initStub() async {
    // Intentionally no-op: wire supabase_flutter.initialize in a later PR.
    _initialized = true;
    _configured = false;
  }

  /// Test / future hook when real client is wired.
  static void debugMarkConfigured(bool value) => _configured = value;
}
