import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:werkly/core/auth/auth_service.dart';
import 'package:werkly/core/auth/auth_session.dart';
import 'package:werkly/core/secure/llm_key_store.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final llmKeyStoreProvider = Provider<LlmKeyStore>((ref) {
  return LlmKeyStore();
});

/// Reactive session — updates on auth service emit.
final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AuthSession>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthSessionNotifier(service);
});

class AuthSessionNotifier extends StateNotifier<AuthSession> {
  AuthSessionNotifier(this._service) : super(_service.session) {
    _service.addListener(_onChange);
  }

  final AuthService _service;

  void _onChange() {
    state = _service.session;
  }

  @override
  void dispose() {
    _service.removeListener(_onChange);
    super.dispose();
  }

  Future<void> mockSignIn({String? email}) async {
    await _service.signInMock(email: email);
  }

  Future<void> signInPassword({
    required String email,
    required String password,
  }) async {
    await _service.signInWithPassword(email: email, password: password);
  }

  Future<void> signInMagicLink({required String email}) async {
    await _service.signInWithMagicLink(email: email);
  }

  Future<void> signOut({bool clearLlmKey = false, LlmKeyStore? keys}) async {
    await _service.signOut();
    if (clearLlmKey && keys != null) {
      await keys.clear();
    }
  }
}

/// Masked last-4 for Settings UI (never full key).
final llmKeyMaskedProvider = FutureProvider<String?>((ref) async {
  return ref.watch(llmKeyStoreProvider).maskedLast4();
});

final llmKeyPresentProvider = FutureProvider<bool>((ref) async {
  return ref.watch(llmKeyStoreProvider).hasKey;
});
