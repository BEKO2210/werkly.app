import 'package:uuid/uuid.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/captions/data/caption_memory_store.dart';
import 'package:werkly/features/captions/data/edge_caption_client.dart';
import 'package:werkly/features/captions/data/mock_caption_generator.dart';
import 'package:werkly/features/captions/domain/caption_models.dart';
import 'package:werkly/features/captions/domain/caption_repository.dart';
import 'package:werkly/features/captions/domain/caption_validation.dart';

/// Orchestrates validation → soft gate → Edge (if configured) else Mock.
/// Online required for generate (checked by caller via connectivity).
class LocalCaptionRepository implements CaptionRepository {
  LocalCaptionRepository({
    required CaptionMemoryStore store,
    MockCaptionGenerator? mock,
    EdgeCaptionClient? edge,
    Uuid? uuid,
    this.preferMock = false,
  })  : _store = store,
        _mock = mock ?? MockCaptionGenerator(),
        _edge = edge ?? EdgeCaptionClient(),
        _uuid = uuid ?? const Uuid();

  final CaptionMemoryStore _store;
  final MockCaptionGenerator _mock;
  final EdgeCaptionClient _edge;
  final Uuid _uuid;

  /// When true (AppFlags.mockCaptions), always use local Mock.
  final bool preferMock;

  EdgeCaptionClient get edgeClient => _edge;
  MockCaptionGenerator get mockGenerator => _mock;

  @override
  Future<CaptionGeneration?> getGeneration(String id) =>
      _store.getGeneration(id);

  @override
  Future<List<CaptionGeneration>> listRecentGenerations({int limit = 20}) =>
      _store.listRecent(limit: limit);

  @override
  Future<List<Favorite>> listFavorites() => _store.listFavorites();

  @override
  Future<Favorite> addFavorite(
    CaptionVariant variant, {
    CaptionLanguage? language,
  }) async {
    final existing = await _store.favoriteByVariantId(variant.id);
    if (existing != null) return existing;
    final fav = Favorite(
      id: _uuid.v4(),
      body: variant.body,
      kind: variant.kind,
      language: language,
      sourceVariantId: variant.id,
      sourceGenerationId: variant.generationId,
      createdAt: DateTime.now().toUtc(),
    );
    await _store.upsertFavorite(fav);
    final gen = await _store.getGeneration(variant.generationId);
    if (gen != null) {
      final updated = gen.variants
          .map((v) => v.id == variant.id ? v.copyWith(isFavorite: true) : v)
          .toList();
      await _store.saveGeneration(gen.copyWith(variants: updated));
    }
    return fav;
  }

  @override
  Future<void> removeFavorite(String favoriteId) =>
      _store.removeFavorite(favoriteId);

  @override
  Future<bool> isVariantFavorite(String variantId) async {
    return (await _store.favoriteByVariantId(variantId)) != null;
  }

  @override
  Future<int> usedThisMonth() async {
    final period = CaptionQuotaSnapshot.currentPeriodUtc();
    return _store.usedForPeriod(period);
  }

  @override
  Future<CaptionQuotaSnapshot> quotaSnapshot({required bool isPro}) async {
    final period = CaptionQuotaSnapshot.currentPeriodUtc();
    final used = await _store.usedForPeriod(period);
    return CaptionQuotaSnapshot(
      used: used,
      limit: QuotaPolicy.captionLimit(isPro: isPro),
      plan: isPro ? 'pro' : 'free',
      period: period,
    );
  }

  @override
  Future<CaptionGeneration> saveGeneration(CaptionGeneration generation) =>
      _store.saveGeneration(generation);

  /// Full generate path. Soft-gate + validation done here.
  /// Prefer Edge when [EdgeCaptionClient.isConfigured]; else Mock.
  /// On Edge error: rethrow [CaptionApiError] for Retry + Klartext (no silent mock).
  Future<GenerateResult> generate({
    required GenerateCaptionRequest request,
    required bool isPro,
    bool forceMock = false,
  }) async {
    final validation = CaptionValidation.validate(request.prompt);
    if (!validation.isValid) {
      return GenerateResult.validation(validation);
    }

    final used = await usedThisMonth();
    if (QuotaPolicy.shouldBlockCaptionGenerate(
      isPro: isPro,
      usedThisMonth: used,
    )) {
      return GenerateResult.paywall(
        CaptionApiError(
          error: 'Monatliches Caption-Kontingent aufgebraucht',
          code: 'quota_exceeded',
          httpStatus: 402,
          details: {
            'used': used,
            'limit': QuotaPolicy.captionLimit(isPro: isPro),
            'plan': isPro ? 'pro' : 'free',
            'period': CaptionQuotaSnapshot.currentPeriodUtc(),
            'paywall_trigger': QuotaPolicy.paywallTriggerCaptions,
          },
        ),
      );
    }

    final sanitized = GenerateCaptionRequest(
      prompt: validation.sanitizedPrompt,
      language: request.language,
      tone: request.tone,
      platform: request.platform,
    );

    final useEdge = !forceMock && !preferMock && _edge.isConfigured;
    try {
      final GenerateCaptionResponse wire;
      final bool usedMock;
      String? note;

      if (useEdge) {
        wire = await _edge.generate(sanitized);
        usedMock = false;
      } else {
        wire = _mock.generate(
          request: sanitized,
          usedBefore: used,
          isPro: isPro,
        );
        usedMock = true;
        note =
            'Lokaler Demo-Generator (Edge nicht konfiguriert · gleiche Mock-Shapes)';
      }

      final variants = [
        ...wire.captions.map((d) => d.toDomain(generationId: wire.generationId)),
        ...wire.hooks.map((d) => d.toDomain(generationId: wire.generationId)),
      ];

      final generation = CaptionGeneration(
        id: wire.generationId,
        prompt: sanitized.prompt,
        language: sanitized.language,
        tone: sanitized.tone,
        platform: sanitized.platform,
        variants: variants,
        createdAt: DateTime.now().toUtc(),
        usedMock: usedMock,
        providerNote: note,
        status: 'ok',
      );

      await _store.saveGeneration(generation);
      await _store.setUsedForPeriod(wire.quota.period, wire.quota.used);

      return GenerateResult.ok(generation, wire.quota);
    } on CaptionApiError catch (e) {
      if (e.isQuotaExceeded) {
        return GenerateResult.paywall(e);
      }
      if (e.isPolicyReject) {
        return GenerateResult.validation(
          CaptionValidationResult(
            isValid: false,
            errors: [e.error],
            sanitizedPrompt: validation.sanitizedPrompt,
            code: e.code,
          ),
        );
      }
      return GenerateResult.failure(e);
    }
  }
}

class GenerateResult {
  const GenerateResult._({
    this.generation,
    this.quota,
    this.validation,
    this.error,
    this.softGated = false,
  });

  final CaptionGeneration? generation;
  final CaptionQuotaSnapshot? quota;
  final CaptionValidationResult? validation;
  final CaptionApiError? error;
  final bool softGated;

  bool get success => generation != null && !softGated;

  factory GenerateResult.ok(
    CaptionGeneration g,
    CaptionQuotaSnapshot q,
  ) =>
      GenerateResult._(generation: g, quota: q);

  factory GenerateResult.validation(CaptionValidationResult v) =>
      GenerateResult._(validation: v);

  factory GenerateResult.paywall(CaptionApiError e) =>
      GenerateResult._(error: e, softGated: true);

  factory GenerateResult.failure(CaptionApiError e) =>
      GenerateResult._(error: e);
}
