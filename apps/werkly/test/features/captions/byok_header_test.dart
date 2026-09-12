import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/captions/data/edge_caption_client.dart';
import 'package:werkly/features/captions/domain/caption_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => WerklySupabase.debugMarkConfigured(false));

  test('GL-04 BYOK sends X-Werkly-LLM-Key when user key present', () async {
    WerklySupabase.debugMarkConfigured(true);
    Map<String, String>? seenHeaders;

    final client = EdgeCaptionClient(
      baseUrl: 'https://example.supabase.co',
      accessTokenProvider: () async => 'user-jwt',
      llmApiKeyProvider: () async => 'sk-byok-secret-never-log',
      mockHeader: false,
      httpPost: (req) async {
        seenHeaders = req.headers;
        return EdgeHttpResponse(
          statusCode: 200,
          body: jsonEncode({
            'generation_id': '11111111-1111-4111-8111-111111111111',
            'captions': [
              for (var i = 0; i < 3; i++)
                {
                  'id': '22222222-2222-4222-8222-22222222222$i',
                  'kind': 'caption',
                  'body': 'Caption $i',
                },
            ],
            'hooks': [
              {
                'id': '33333333-3333-4333-8333-333333333331',
                'kind': 'hook',
                'body': 'Hook',
              },
            ],
            'quota': {
              'used': 1,
              'limit': 10,
              'plan': 'free',
              'period': '2026-09',
            },
          }),
        );
      },
    );

    await client.generate(
      const GenerateCaptionRequest(
        prompt: 'Test',
        language: CaptionLanguage.de,
      ),
    );

    expect(seenHeaders!['Authorization'], 'Bearer user-jwt');
    expect(seenHeaders!['X-Werkly-LLM-Key'], 'sk-byok-secret-never-log');
    expect(seenHeaders!.containsKey('X-Werkly-Mock'), isFalse);
  });

  test('GL-04 server mode: JWT only when no user key', () async {
    WerklySupabase.debugMarkConfigured(true);
    Map<String, String>? seenHeaders;

    final client = EdgeCaptionClient(
      baseUrl: 'https://example.supabase.co',
      accessTokenProvider: () async => 'user-jwt',
      llmApiKeyProvider: () async => null,
      mockHeader: false,
      httpPost: (req) async {
        seenHeaders = req.headers;
        return const EdgeHttpResponse(
          statusCode: 503,
          body: '{"error":"upstream","code":"upstream_unavailable"}',
        );
      },
    );

    try {
      await client.generate(
        const GenerateCaptionRequest(
          prompt: 'Test',
          language: CaptionLanguage.de,
        ),
      );
    } catch (_) {}

    expect(seenHeaders!['Authorization'], 'Bearer user-jwt');
    expect(seenHeaders!.containsKey('X-Werkly-LLM-Key'), isFalse);
  });
}
