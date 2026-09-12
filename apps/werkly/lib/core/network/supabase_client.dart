/// Supabase stub — no URL/anon key in scaffold (no secrets).
class WerklySupabase {
  WerklySupabase._();

  static bool get isInitialized => _initialized;
  static bool _initialized = false;

  /// Call from bootstrap with env-injected values later.
  static Future<void> initStub() async {
    // Intentionally no-op: wire supabase_flutter.initialize in a later PR.
    _initialized = true;
  }
}
