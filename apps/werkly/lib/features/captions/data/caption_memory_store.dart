import 'package:werkly/features/captions/domain/caption_models.dart';

/// Lean in-memory persistence for generations, favorites, monthly quota.
class CaptionMemoryStore {
  final Map<String, CaptionGeneration> _generations = {};
  final Map<String, Favorite> _favorites = {};
  /// period (YYYY-MM UTC) → used count
  final Map<String, int> _quotaUsed = {};

  Future<CaptionGeneration?> getGeneration(String id) async =>
      _generations[id];

  Future<List<CaptionGeneration>> listRecent({int limit = 20}) async {
    final list = _generations.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(limit).toList();
  }

  Future<CaptionGeneration> saveGeneration(CaptionGeneration g) async {
    _generations[g.id] = g;
    return g;
  }

  Future<List<Favorite>> listFavorites() async {
    final list = _favorites.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<Favorite> upsertFavorite(Favorite f) async {
    _favorites[f.id] = f;
    return f;
  }

  Future<void> removeFavorite(String id) async {
    _favorites.remove(id);
  }

  Future<Favorite?> favoriteByVariantId(String variantId) async {
    for (final f in _favorites.values) {
      if (f.sourceVariantId == variantId) return f;
    }
    return null;
  }

  Future<int> usedForPeriod(String period) async => _quotaUsed[period] ?? 0;

  Future<int> incrementQuota(String period) async {
    final next = (_quotaUsed[period] ?? 0) + 1;
    _quotaUsed[period] = next;
    return next;
  }

  /// Sync local counter to server-reported used (after Edge 200).
  Future<void> setUsedForPeriod(String period, int used) async {
    _quotaUsed[period] = used;
  }

  /// Test helper.
  Future<void> debugSetUsed(String period, int used) async {
    _quotaUsed[period] = used;
  }
}
