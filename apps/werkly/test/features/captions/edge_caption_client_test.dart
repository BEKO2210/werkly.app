import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/captions/data/edge_caption_client.dart';
import 'package:werkly/features/captions/domain/caption_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    WerklySupabase.debugMarkConfigured(false);
  });

  test('EdgeCaptionClient parses 200 mock JSON via injected http', () async {
    WerklySupabase.debugMarkConfigured(true);
    final raw = await rootBundle
        .loadString('assets/contracts/mocks/generate-caption-200.json');

    final client = EdgeCaptionClient(
      baseUrl: 'https://example.supabase.co',
      accessTokenProvider: () async => 'test-jwt',
      mockHeader: true,
      httpPost: (req) async {
        expect(req.uri.path, contains('/functions/v1/generate-caption'));
        expect(req.headers['Authorization'], 'Bearer test-jwt');
        expect(req.headers['X-Werkly-Mock'], '1');
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['prompt'], isNotEmpty);
        expect(body['language'], anyOf('de', 'en'));
        return EdgeHttpResponse(statusCode: 200, body: raw);
      },
    );

    expect(client.isConfigured, isTrue);
    final res = await client.generate(
      const GenerateCaptionRequest(
        prompt: 'Morgenroutine',
        language: CaptionLanguage.de,
        platform: CaptionPlatformHint.ig,
      ),
    );
    expect(res.captions.length, greaterThanOrEqualTo(3));
    expect(res.hooks.length, greaterThanOrEqualTo(1));
    expect(res.quota.period, '2026-09');
  });

  test('EdgeCaptionClient maps 402 to CaptionApiError', () async {
    WerklySupabase.debugMarkConfigured(true);
    final raw = await rootBundle
        .loadString('assets/contracts/mocks/generate-caption-402.json');
    final client = EdgeCaptionClient(
      baseUrl: 'https://example.supabase.co',
      accessTokenProvider: () async => 'test-jwt',
      httpPost: (_) async => EdgeHttpResponse(statusCode: 402, body: raw),
    );
    expect(
      () => client.generate(
        const GenerateCaptionRequest(
          prompt: 'x',
          language: CaptionLanguage.de,
        ),
      ),
      throwsA(
        isA<CaptionApiError>()
            .having((e) => e.isQuotaExceeded, 'quota', isTrue)
            .having((e) => e.paywallTrigger, 'trigger', 'limit_captions'),
      ),
    );
  });
}
