import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/captions/domain/caption_models.dart';

/// POST `/functions/v1/generate-caption` (GENERATE-CAPTION-V1 + BYOK).
///
/// When [WerklySupabase.isConfigured] is false, callers should use
/// [MockCaptionGenerator] instead (same JSON shapes as contracts/mocks).
///
/// BYOK: optional [llmApiKeyProvider] → header `X-Werkly-LLM-Key`
/// (LIVE-AUTH-CAPTION-BYOK-V1). Key is never logged.
class EdgeCaptionClient {
  EdgeCaptionClient({
    this.baseUrl,
    this.accessTokenProvider,
    this.llmApiKeyProvider,
    this.mockHeader = false,
    Future<EdgeHttpResponse> Function(EdgeHttpRequest request)? httpPost,
  }) : _httpPost = httpPost;

  /// e.g. `https://<ref>.supabase.co` — without trailing slash.
  final String? baseUrl;
  final Future<String?> Function()? accessTokenProvider;

  /// Optional user BYOK from secure storage — never logged.
  final Future<String?> Function()? llmApiKeyProvider;

  /// Sends `X-Werkly-Mock: 1` when true (force mock Edge path).
  final bool mockHeader;

  final Future<EdgeHttpResponse> Function(EdgeHttpRequest request)? _httpPost;

  bool get isConfigured =>
      WerklySupabase.isConfigured &&
      (baseUrl != null && baseUrl!.isNotEmpty);

  Uri get _endpoint {
    final root = baseUrl!.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$root/functions/v1/generate-caption');
  }

  /// Invokes Edge. Throws [CaptionApiError] on 4xx/5xx or transport failure.
  Future<GenerateCaptionResponse> generate(GenerateCaptionRequest request) async {
    if (!isConfigured) {
      throw const CaptionApiError(
        error: 'Supabase nicht konfiguriert',
        code: 'upstream_unavailable',
        httpStatus: 503,
      );
    }

    final token = await (accessTokenProvider?.call() ?? Future.value(null));
    if (token == null || token.isEmpty) {
      throw const CaptionApiError(
        error: 'Nicht angemeldet',
        code: 'unauthorized',
        httpStatus: 401,
      );
    }

    // Read key once for header — do not log / echo.
    String? byok;
    try {
      byok = await llmApiKeyProvider?.call();
      if (byok != null && byok.trim().isEmpty) byok = null;
    } catch (_) {
      byok = null;
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      if (mockHeader) 'X-Werkly-Mock': '1',
      if (byok != null) 'X-Werkly-LLM-Key': byok,
    };

    final body = jsonEncode(request.toJson());
    final EdgeHttpResponse res;
    try {
      final post = _httpPost;
      if (post != null) {
        res = await post(
          EdgeHttpRequest(uri: _endpoint, headers: headers, body: body),
        );
      } else {
        res = await _defaultPost(
          EdgeHttpRequest(uri: _endpoint, headers: headers, body: body),
        );
      }
    } catch (e) {
      throw CaptionApiError(
        error: 'KI gerade nicht erreichbar',
        code: 'upstream_unavailable',
        httpStatus: 503,
        details: {'cause': e.toString()},
      );
    }

    final decoded = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return GenerateCaptionResponse.fromJson(decoded);
    }

    // Never echo key material from error bodies into UI beyond server message.
    throw CaptionApiError.fromJson(decoded, httpStatus: res.statusCode);
  }

  static Future<EdgeHttpResponse> _defaultPost(EdgeHttpRequest req) async {
    final response = await http
        .post(
          req.uri,
          headers: req.headers,
          body: req.body,
        )
        .timeout(const Duration(seconds: 30));
    return EdgeHttpResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}

class EdgeHttpRequest {
  const EdgeHttpRequest({
    required this.uri,
    required this.headers,
    required this.body,
  });

  final Uri uri;
  final Map<String, String> headers;
  final String body;
}

class EdgeHttpResponse {
  const EdgeHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
