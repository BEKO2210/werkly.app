import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Client-only BYOK store. Key never logged; not synced to profiles.
class LlmKeyStore {
  LlmKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const storageKey = 'werkly_llm_api_key';

  final FlutterSecureStorage _storage;

  /// In-memory fallback when plugin unavailable (tests / desktop CI).
  String? _memoryFallback;

  Future<void> save(String raw) async {
    final value = raw.trim();
    if (value.isEmpty) {
      await clear();
      return;
    }
    try {
      await _storage.write(key: storageKey, value: value);
      _memoryFallback = null;
    } catch (_) {
      _memoryFallback = value;
    }
  }

  Future<String?> read() async {
    try {
      final v = await _storage.read(key: storageKey);
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {}
    return _memoryFallback;
  }

  Future<void> clear() async {
    _memoryFallback = null;
    try {
      await _storage.delete(key: storageKey);
    } catch (_) {}
  }

  Future<bool> get hasKey async {
    final v = await read();
    return v != null && v.isNotEmpty;
  }

  /// Masked display: `••••1234` (last 4). Empty → null.
  /// Never returns the full key.
  Future<String?> maskedLast4() async {
    final v = await read();
    if (v == null || v.isEmpty) return null;
    if (v.length <= 4) return '••••';
    return '••••${v.substring(v.length - 4)}';
  }
}
