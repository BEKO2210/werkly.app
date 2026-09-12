import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/captions/data/caption_memory_store.dart';
import 'package:werkly/features/captions/data/edge_caption_client.dart';
import 'package:werkly/features/captions/data/local_caption_repository.dart';
import 'package:werkly/features/captions/data/mock_caption_generator.dart';
import 'package:werkly/features/captions/domain/caption_models.dart';
import 'package:werkly/features/captions/domain/caption_repository.dart';

final captionMemoryStoreProvider = Provider<CaptionMemoryStore>((ref) {
  return CaptionMemoryStore();
});

final edgeCaptionClientProvider = Provider<EdgeCaptionClient>((ref) {
  return EdgeCaptionClient();
});

final captionRepositoryProvider = Provider<CaptionRepository>((ref) {
  return LocalCaptionRepository(
    store: ref.watch(captionMemoryStoreProvider),
    mock: MockCaptionGenerator(),
    edge: ref.watch(edgeCaptionClientProvider),
  );
});

final captionQuotaProvider =
    FutureProvider<CaptionQuotaSnapshot>((ref) async {
  final isPro = ref.watch(isProProvider);
  final repo = ref.watch(captionRepositoryProvider);
  return repo.quotaSnapshot(isPro: isPro);
});

final captionFavoritesProvider = FutureProvider<List<Favorite>>((ref) async {
  return ref.watch(captionRepositoryProvider).listFavorites();
});

final captionGenerationProvider =
    FutureProvider.family<CaptionGeneration?, String>((ref, id) async {
  return ref.watch(captionRepositoryProvider).getGeneration(id);
});

/// True when device reports no network (generate requires online).
final captionOnlineProvider = FutureProvider<bool>((ref) async {
  try {
    final result = await Connectivity().checkConnectivity();
    // connectivity_plus 6+: List<ConnectivityResult>
    return result.any((e) => e != ConnectivityResult.none);
  } catch (_) {
    // Degraded: allow mock path in tests / missing plugin.
    return true;
  }
});

class CaptionGenerateNotifier extends StateNotifier<AsyncValue<void>> {
  CaptionGenerateNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  LocalCaptionRepository get _repo =>
      _ref.read(captionRepositoryProvider) as LocalCaptionRepository;

  Future<GenerateResult> generate({
    required String prompt,
    required CaptionLanguage language,
    String? tone,
    CaptionPlatformHint? platform,
  }) async {
    state = const AsyncLoading();
    final online = await _ref.read(captionOnlineProvider.future);
    if (!online) {
      final err = const CaptionApiError(
        error: 'Offline — Caption-Generierung braucht eine Verbindung.',
        code: 'upstream_unavailable',
        httpStatus: 503,
      );
      state = AsyncError(err, StackTrace.current);
      return GenerateResult.failure(err);
    }

    final isPro = _ref.read(isProProvider);
    final result = await _repo.generate(
      request: GenerateCaptionRequest(
        prompt: prompt,
        language: language,
        tone: tone,
        platform: platform,
      ),
      isPro: isPro,
    );
    _ref.invalidate(captionQuotaProvider);
    if (result.success) {
      state = const AsyncData(null);
    } else if (result.softGated) {
      state = const AsyncData(null);
    } else if (result.error != null) {
      state = AsyncError(result.error!, StackTrace.current);
    } else {
      state = const AsyncData(null);
    }
    return result;
  }

  Future<GenerateResult> regenerate(CaptionGeneration previous) {
    return generate(
      prompt: previous.prompt,
      language: previous.language,
      tone: previous.tone,
      platform: previous.platform,
    );
  }

  Future<void> toggleFavorite(CaptionVariant variant, {CaptionLanguage? language}) async {
    final repo = _repo;
    final existing = await repo.isVariantFavorite(variant.id);
    if (existing) {
      final favs = await repo.listFavorites();
      final match = favs.where((f) => f.sourceVariantId == variant.id);
      for (final f in match) {
        await repo.removeFavorite(f.id);
      }
    } else {
      await repo.addFavorite(variant, language: language);
    }
    _ref.invalidate(captionFavoritesProvider);
    _ref.invalidate(captionGenerationProvider(variant.generationId));
  }
}

final captionGenerateNotifierProvider =
    StateNotifierProvider<CaptionGenerateNotifier, AsyncValue<void>>((ref) {
  return CaptionGenerateNotifier(ref);
});

/// Helper for soft-gate checks in UI before navigation.
bool captionWouldSoftGate(WidgetRef ref, int used) {
  final isPro = ref.read(isProProvider);
  return QuotaPolicy.shouldBlockCaptionGenerate(
    isPro: isPro,
    usedThisMonth: used,
  );
}
