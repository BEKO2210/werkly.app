import 'dart:convert';

import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/captions/domain/caption_models.dart';

/// POST `/functions/v1/generate-caption` (GENERATE-CAPTION-V1).
///
/// When [WerklySupabase.isConfigured] is false, callers should use
/// [MockCaptionGenerator] instead (same JSON shapes as contracts/mocks).
class EdgeCaptionClient {
  EdgeCaptionClient({
    this.baseUrl,
    this.accessTokenProvider,
    this.mockHeader = true,
    Future<EdgeHttpResponse> Function(EdgeHttpRequest request)? httpPost,
  }) : _httpPost = httpPost;

  /// e.g. `https://<ref>.supabase.co` — without trailing slash.
  final String? baseUrl;
  final Future<String?> Function()? accessTokenProvider;

  /// Sends `X-Werkly-Mock: 1` until live LLM is deployed.
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

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      if (mockHeader) 'X-Werkly-Mock': '1',
    };

    final body = jsonEncode(request.toJson());
    final EdgeHttpResponse res;
    try {
      if (_httpPost != null) {
        res = await _httpPost!(
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

    throw CaptionApiError.fromJson(decoded, httpStatus: res.statusCode);
  }

  static Future<EdgeHttpResponse> _defaultPost(EdgeHttpRequest req) async {
    // Avoid pulling dart:io into tests — inject [_httpPost] in production later
    // via supabase.functions.invoke. Scaffold uses injected client or mock path.
    throw UnsupportedError(
      'Inject httpPost or use MockCaptionGenerator when Edge is not wired',
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
