import 'package:werkly/features/captions/domain/caption_models.dart';

/// F2 caption repository — generate, history, favorites, quota.
abstract class CaptionRepository {
  Future<CaptionGeneration?> getGeneration(String id);

  Future<List<CaptionGeneration>> listRecentGenerations({int limit = 20});

  Future<List<Favorite>> listFavorites();

  Future<Favorite> addFavorite(CaptionVariant variant, {CaptionLanguage? language});

  Future<void> removeFavorite(String favoriteId);

  Future<bool> isVariantFavorite(String variantId);

  /// Generations used in the current calendar month (Europe/Berlin ok).
  Future<int> usedThisMonth();

  Future<CaptionQuotaSnapshot> quotaSnapshot({required bool isPro});

  /// Persist a finished generation and increment monthly quota.
  Future<CaptionGeneration> saveGeneration(CaptionGeneration generation);
}
