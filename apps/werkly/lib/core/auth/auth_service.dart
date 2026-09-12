import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:werkly/core/auth/auth_session.dart';
import 'package:werkly/core/config/app_flags.dart';
import 'package:werkly/core/network/supabase_client.dart';

/// Auth facade: live Supabase when configured, else clearly labeled mock.
class AuthService {
  AuthService();

  AuthSession _session = AuthSession.signedOut;
  final _listeners = <VoidCallback>[];

  AuthSession get session => _session;

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void _emit() {
    for (final l in List<VoidCallback>.from(_listeners)) {
      l();
    }
  }

  void _set(AuthSession next) {
    _session = next;
    _emit();
  }

  /// Call after [WerklySupabase] init. Restores live session if any.
  Future<void> restore() async {
    if (AppFlags.mockAuth || !WerklySupabase.isConfigured) {
      return;
    }
    try {
      final client = Supabase.instance.client;
      final existing = client.auth.currentSession;
      if (existing != null) {
        _applyUser(existing.user);
      }
      client.auth.onAuthStateChange.listen((data) {
        final user = data.session?.user;
        if (user == null) {
          _set(AuthSession.signedOut);
        } else {
          _applyUser(user);
        }
      });
    } catch (_) {
      // Soft: stay signed out.
    }
  }

  void _applyUser(User user) {
    _set(
      AuthSession(
        mode: AuthMode.live,
        userId: user.id,
        email: user.email,
        displayName: user.userMetadata?['display_name'] as String? ??
            user.userMetadata?['full_name'] as String?,
      ),
    );
  }

  /// Soft mock login — only when [AppFlags.mockAuth].
  Future<AuthSession> signInMock({String? email}) async {
    final e = (email == null || email.trim().isEmpty)
        ? 'gast@mock.werkly'
        : email.trim();
    _set(
      AuthSession(
        mode: AuthMode.mockGuest,
        userId: 'mock-guest',
        email: e,
        displayName: 'Gast',
      ),
    );
    return _session;
  }

  /// Password sign-in when live Supabase is configured.
  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (AppFlags.mockAuth || !WerklySupabase.isConfigured) {
      return signInMock(email: email);
    }
    final res = await Supabase.instance.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = res.user;
    if (user == null) {
      throw StateError('Anmeldung fehlgeschlagen');
    }
    _applyUser(user);
    return _session;
  }

  /// Magic-link / OTP stub: sends email when live; mock otherwise.
  Future<void> signInWithMagicLink({required String email}) async {
    if (AppFlags.mockAuth || !WerklySupabase.isConfigured) {
      await signInMock(email: email);
      return;
    }
    await Supabase.instance.client.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
    );
  }

  Future<void> signOut() async {
    if (WerklySupabase.isConfigured && !AppFlags.mockAuth) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }
    _set(AuthSession.signedOut);
  }

  Future<String?> accessToken() async {
    if (_session.mode == AuthMode.mockGuest) {
      return 'mock-jwt';
    }
    if (!WerklySupabase.isConfigured) return null;
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }
}
