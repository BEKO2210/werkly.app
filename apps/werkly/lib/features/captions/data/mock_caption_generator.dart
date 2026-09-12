import 'package:uuid/uuid.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/captions/domain/caption_models.dart';
import 'package:werkly/features/captions/domain/caption_validation.dart';

/// Local Flutter mock — same JSON shapes as `contracts/mocks/generate-caption-*.json`.
/// Deterministic templates with [topic] inserted; ≥3 captions + ≥1 hook; instant.
class MockCaptionGenerator {
  MockCaptionGenerator({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// Throws [CaptionApiError] for policy (400) — caller maps to inline UI.
  /// Returns wire [GenerateCaptionResponse] (200 shape).
  GenerateCaptionResponse generate({
    required GenerateCaptionRequest request,
    required int usedBefore,
    required bool isPro,
  }) {
    final validation = CaptionValidation.validate(request.prompt);
    if (!validation.isValid) {
      throw CaptionApiError(
        error: validation.errors.first,
        code: validation.code ?? 'policy_reject',
        httpStatus: 400,
        details: const {'reason': 'empty_or_unsafe'},
      );
    }

    final limit = QuotaPolicy.captionLimit(isPro: isPro);
    if (QuotaPolicy.shouldBlockCaptionGenerate(
      isPro: isPro,
      usedThisMonth: usedBefore,
    )) {
      final period = CaptionQuotaSnapshot.currentPeriodUtc();
      throw CaptionApiError(
        error: 'Monatliches Caption-Kontingent aufgebraucht',
        code: 'quota_exceeded',
        httpStatus: 402,
        details: {
          'used': usedBefore,
          'limit': limit,
          'plan': isPro ? 'pro' : 'free',
          'period': period,
          'paywall_trigger': QuotaPolicy.paywallTriggerCaptions,
        },
      );
    }

    final topic = validation.sanitizedPrompt;
    final generationId = _uuid.v4();
    final lang = request.language;
    final captions = _captionBodies(lang, topic)
        .map(
          (body) => CaptionVariantDto(
            id: _uuid.v4(),
            kind: 'caption',
            body: body,
          ),
        )
        .toList();
    final hooks = _hookBodies(lang, topic)
        .map(
          (body) => CaptionVariantDto(
            id: _uuid.v4(),
            kind: 'hook',
            body: body,
          ),
        )
        .toList();

    assert(captions.length >= 3);
    assert(hooks.length >= 1);

    final used = usedBefore + 1;
    return GenerateCaptionResponse(
      generationId: generationId,
      captions: captions,
      hooks: hooks,
      quota: CaptionQuotaSnapshot(
        used: used,
        limit: limit,
        plan: isPro ? 'pro' : 'free',
        period: CaptionQuotaSnapshot.currentPeriodUtc(),
      ),
    );
  }

  List<String> _captionBodies(CaptionLanguage lang, String topic) {
    if (lang == CaptionLanguage.en) {
      return [
        'About "$topic" — 3 takeaways I keep coming back to. Save this for later.',
        'Creator note on $topic: keep it simple, ship daily, talk to your audience.',
        'If you care about $topic, try this stack today — small steps, big output.',
        'Hot take: $topic works when you stop waiting for perfect and start posting.',
      ];
    }
    return [
      'Thema „$topic“ — 3 Punkte, die ich nicht mehr missen will. Speichere das.',
      'Creator-Tipp zu $topic: klar bleiben, täglich posten, mit der Community reden.',
      'Wenn dich $topic beschäftigt: kleine Systeme schlagen Motivation. Los geht’s.',
      'Ehrlich: Bei $topic zählt Konstanz — nicht der nächste Perfect-Take.',
    ];
  }

  List<String> _hookBodies(CaptionLanguage lang, String topic) {
    if (lang == CaptionLanguage.en) {
      return [
        'Stop scrolling if "$topic" keeps stressing you out —',
        'Wait — this $topic tip changed my week:',
      ];
    }
    return [
      'Stop scrolling, wenn dich „$topic“ ausbrennt —',
      'Warte — dieser Tipp zu $topic hat meine Woche verändert:',
    ];
  }
}
