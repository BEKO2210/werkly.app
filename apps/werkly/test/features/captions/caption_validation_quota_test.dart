import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/captions/data/mock_caption_generator.dart';
import 'package:werkly/features/captions/domain/caption_models.dart';
import 'package:werkly/features/captions/domain/caption_validation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CaptionValidation (F2 safety / contract)', () {
    test('rejects empty and whitespace', () {
      expect(CaptionValidation.validate('').isValid, isFalse);
      expect(CaptionValidation.validate('   ').isValid, isFalse);
      expect(CaptionValidation.validate(null).isValid, isFalse);
    });

    test('rejects over 500 chars', () {
      final long = 'a' * 501;
      final r = CaptionValidation.validate(long);
      expect(r.isValid, isFalse);
    });

    test('rejects BLOCK token case-insensitive (contract mock)', () {
      expect(CaptionValidation.validate('please BLOCK this').isValid, isFalse);
      expect(CaptionValidation.validate('block').isValid, isFalse);
      expect(CaptionValidation.validate('Blöck').isValid, isTrue); // not ASCII block
      expect(
        CaptionValidation.validate('please BLOCK this').code,
        'policy_reject',
      );
    });

    test('accepts normal topic', () {
      final r = CaptionValidation.validate('Morgenroutine für Creator');
      expect(r.isValid, isTrue);
      expect(r.sanitizedPrompt, 'Morgenroutine für Creator');
    });
  });

  group('Quota soft gate (limit_captions)', () {
    test('Free blocks at 10; Pro soft-cap 500', () {
      expect(shouldSoftGateCaptionGenerate(9), isFalse);
      expect(shouldSoftGateCaptionGenerate(10), isTrue);
      expect(shouldSoftGateCaptionGenerate(10, isPro: true), isFalse);
      expect(shouldSoftGateCaptionGenerate(500, isPro: true), isTrue);
      expect(QuotaPolicy.freeMonthlyCaptions, 10);
      expect(QuotaPolicy.paywallTriggerCaptions, 'limit_captions');
    });

    test('period YYYY-MM UTC', () {
      final p = CaptionQuotaSnapshot.currentPeriodUtc(DateTime.utc(2026, 9, 12));
      expect(p, '2026-09');
    });
  });

  group('MockCaptionGenerator', () {
    test('returns ≥3 captions + ≥1 hook DE with topic', () {
      final mock = MockCaptionGenerator();
      final res = mock.generate(
        request: const GenerateCaptionRequest(
          prompt: 'Morgenroutine',
          language: CaptionLanguage.de,
          platform: CaptionPlatformHint.ig,
        ),
        usedBefore: 0,
        isPro: false,
      );
      expect(res.captions.length, greaterThanOrEqualTo(3));
      expect(res.hooks.length, greaterThanOrEqualTo(1));
      expect(res.captions.every((c) => c.kind == 'caption'), isTrue);
      expect(res.hooks.every((h) => h.kind == 'hook'), isTrue);
      expect(res.captions.first.body.contains('Morgenroutine'), isTrue);
      expect(res.quota.used, 1);
      expect(res.quota.limit, 10);
      expect(res.quota.plan, 'free');
      expect(res.generationId, isNotEmpty);
    });

    test('EN templates and regenerate gets new id', () {
      final mock = MockCaptionGenerator();
      final a = mock.generate(
        request: const GenerateCaptionRequest(
          prompt: 'morning routine',
          language: CaptionLanguage.en,
        ),
        usedBefore: 3,
        isPro: false,
      );
      final b = mock.generate(
        request: const GenerateCaptionRequest(
          prompt: 'morning routine',
          language: CaptionLanguage.en,
        ),
        usedBefore: 4,
        isPro: false,
      );
      expect(a.generationId, isNot(b.generationId));
      expect(a.captions.length, greaterThanOrEqualTo(3));
      expect(a.hooks.length, greaterThanOrEqualTo(1));
      expect(a.quota.used, 4);
      expect(b.quota.used, 5);
    });

    test('402 when free quota exhausted', () {
      final mock = MockCaptionGenerator();
      expect(
        () => mock.generate(
          request: const GenerateCaptionRequest(
            prompt: 'ok topic',
            language: CaptionLanguage.de,
          ),
          usedBefore: 10,
          isPro: false,
        ),
        throwsA(
          isA<CaptionApiError>().having((e) => e.code, 'code', 'quota_exceeded'),
        ),
      );
    });
  });

  group('Contract mock JSON shapes', () {
    test('parses generate-caption-200.json', () async {
      final raw = await rootBundle
          .loadString('assets/contracts/mocks/generate-caption-200.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final res = GenerateCaptionResponse.fromJson(json);
      expect(res.captions.length, greaterThanOrEqualTo(3));
      expect(res.hooks.length, greaterThanOrEqualTo(1));
      expect(res.quota.period, '2026-09');
      expect(res.quota.used, 4);
      expect(res.quota.limit, 10);
    });

    test('parses 402 + 400 error fixtures', () async {
      final raw402 = await rootBundle
          .loadString('assets/contracts/mocks/generate-caption-402.json');
      final e402 = CaptionApiError.fromJson(
        jsonDecode(raw402) as Map<String, dynamic>,
        httpStatus: 402,
      );
      expect(e402.isQuotaExceeded, isTrue);
      expect(e402.paywallTrigger, 'limit_captions');

      final raw400 = await rootBundle
          .loadString('assets/contracts/mocks/generate-caption-400.json');
      final e400 = CaptionApiError.fromJson(
        jsonDecode(raw400) as Map<String, dynamic>,
        httpStatus: 400,
      );
      expect(e400.isPolicyReject, isTrue);
    });
  });
}
