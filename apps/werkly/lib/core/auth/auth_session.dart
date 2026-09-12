/// Auth session snapshot for Account UI + router redirect.
enum AuthMode {
  /// Soft local guest — labeled clearly when Supabase not configured.
  mockGuest,
  /// Signed in via Supabase Auth.
  live,
  /// Not authenticated.
  signedOut,
}

class AuthSession {
  const AuthSession({
    required this.mode,
    this.userId,
    this.email,
    this.displayName,
  });

  final AuthMode mode;
  final String? userId;
  final String? email;
  final String? displayName;

  bool get isAuthenticated =>
      mode == AuthMode.live || mode == AuthMode.mockGuest;

  bool get isMock => mode == AuthMode.mockGuest;

  bool get isLive => mode == AuthMode.live;

  String get emailOrGuestLabel {
    if (email != null && email!.isNotEmpty) return email!;
    if (mode == AuthMode.mockGuest) return 'Gast / Mock';
    return 'Nicht angemeldet';
  }

  String get displayLabel {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (email != null && email!.isNotEmpty) {
      final at = email!.indexOf('@');
      return at > 0 ? email!.substring(0, at) : email!;
    }
    if (mode == AuthMode.mockGuest) return 'Gast';
    return 'Konto';
  }

  static const signedOut = AuthSession(mode: AuthMode.signedOut);

  AuthSession copyWith({
    AuthMode? mode,
    String? userId,
    String? email,
    String? displayName,
  }) {
    return AuthSession(
      mode: mode ?? this.mode,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }
}
