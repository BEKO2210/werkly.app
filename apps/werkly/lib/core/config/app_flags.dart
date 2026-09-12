import 'package:werkly/core/config/app_env.dart';
import 'package:werkly/core/network/supabase_client.dart';

/// Feature flags derived from config presence (no remote toggle yet).
///
/// | Flag | True when |
/// |------|-----------|
/// | [mockAuth] | Supabase URL+anon **not** configured |
/// | [mockCaptions] | Live Edge path not usable (no Supabase) |
/// | [mockStripe] | Stripe Edge not usable (no Supabase) |
abstract final class AppFlags {
  static bool get mockAuth => !AppEnv.hasSupabaseConfig;

  static bool get mockCaptions => !WerklySupabase.isConfigured;

  static bool get mockStripe => !WerklySupabase.isConfigured;

  static bool get liveAuth => !mockAuth;

  static bool get liveCaptionsPossible => WerklySupabase.isConfigured;

  /// GL-04: Edge generate-caption (server mode OR BYOK header) when configured.
  static bool get useLiveCaptions =>
      WerklySupabase.isConfigured && !mockCaptions;

  /// Snapshot for debug / Settings „Über“ / G-Live GL-06.
  static Map<String, bool> get snapshot => {
        'mockAuth': mockAuth,
        'mockCaptions': mockCaptions,
        'mockStripe': mockStripe,
        'useLiveCaptions': useLiveCaptions,
        'supabaseConfigured': WerklySupabase.isConfigured,
      };
}
