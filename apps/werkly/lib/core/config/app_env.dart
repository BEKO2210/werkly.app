/// Compile-time env via `--dart-define=KEY=value`. No secrets in repo.
abstract final class AppEnv {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Optional public app base for hub links (not a secret).
  static const publicAppBase = String.fromEnvironment(
    'WERKLY_PUBLIC_BASE',
    defaultValue: 'https://werkly.app',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}
