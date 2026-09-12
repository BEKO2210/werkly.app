import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:werkly/core/config/app_env.dart';

/// Supabase bootstrap — only initializes when URL+anon are dart-defined.
class WerklySupabase {
  WerklySupabase._();

  static bool get isInitialized => _initialized;
  static bool _initialized = false;

  /// True only after real `Supabase.initialize` with URL+anon key.
  static bool get isConfigured => _configured;
  static bool _configured = false;

  static String? get url => _configured ? AppEnv.supabaseUrl : null;

  /// Prefer [initFromEnv]; stub keeps offline-first scaffold working.
  static Future<void> initStub() async {
    _initialized = true;
    _configured = false;
  }

  /// Initializes supabase_flutter when `SUPABASE_URL` + `SUPABASE_ANON_KEY`
  /// are present via `--dart-define`. Never embeds secrets in source.
  static Future<void> initFromEnv() async {
    if (!AppEnv.hasSupabaseConfig) {
      await initStub();
      return;
    }
    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl.trim(),
        publishableKey: AppEnv.supabaseAnonKey.trim(),
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _initialized = true;
      _configured = true;
    } catch (_) {
      // Soft degrade to stub — app remains usable with mock auth.
      await initStub();
    }
  }

  /// Test / future hook when real client is wired.
  static void debugMarkConfigured(bool value) => _configured = value;
}
