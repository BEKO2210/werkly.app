import 'dart:convert';

import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/captions/data/edge_caption_client.dart';
import 'package:werkly/features/hub/data/hub_memory_store.dart';
import 'package:werkly/features/hub/domain/public_hub_api.dart';

/// Edge `GET /functions/v1/public-hub?slug=` (OpenAPI operationId: publicHub).
///
/// When Supabase is not configured, serves local mock from [HubMemoryStore]
/// with the same JSON shape as `assets/contracts/mocks/public-hub-200.json`.
class PublicHubClient {
  PublicHubClient({
    HubMemoryStore? store,
    this.baseUrl,
    Future<EdgeHttpResponse> Function(Uri uri, Map<String, String> headers)?
        httpGet,
  })  : _store = store,
        _httpGet = httpGet;

  HubMemoryStore? _store;
  final String? baseUrl;
  final Future<EdgeHttpResponse> Function(Uri uri, Map<String, String> headers)?
      _httpGet;

  void bindStore(HubMemoryStore store) => _store = store;

  bool get isConfigured =>
      WerklySupabase.isConfigured &&
      baseUrl != null &&
      baseUrl!.isNotEmpty &&
      _httpGet != null;

  Uri _endpoint(String slug) {
    final root = baseUrl!.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$root/functions/v1/public-hub').replace(
      queryParameters: {'slug': slug, 'format': 'json'},
    );
  }

  /// Returns OpenAPI [PublicHubDto]. Throws [HubApiError] on 404 / transport.
  Future<PublicHubDto> getPublicHub({required String slug}) async {
    if (isConfigured) {
      return _fetchEdge(slug);
    }
    return _fetchLocalMock(slug);
  }

  /// Raw JSON map (contract shape) — useful for tests / debug.
  Future<Map<String, dynamic>> getPublicHubJson({required String slug}) async {
    final dto = await getPublicHub(slug: slug);
    return dto.toJson();
  }

  Future<PublicHubDto> _fetchEdge(String slug) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    final EdgeHttpResponse res;
    try {
      res = await _httpGet!(_endpoint(slug), headers);
    } catch (e) {
      throw HubApiError(
        error: 'Public Hub nicht erreichbar',
        code: 'upstream_unavailable',
        httpStatus: 503,
        details: {'cause': e.toString()},
      );
    }
    final decoded = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return PublicHubDto.fromJson(decoded);
    }
    throw HubApiError.fromJson(decoded, httpStatus: res.statusCode);
  }

  Future<PublicHubDto> _fetchLocalMock(String slug) async {
    final store = _store;
    if (store == null) {
      throw const HubApiError(
        error: 'Hub nicht gefunden',
        code: 'not_found',
        httpStatus: 404,
      );
    }
    final hub = await store.bySlug(slug);
    if (hub == null || !hub.isPublic) {
      throw const HubApiError(
        error: 'Hub nicht gefunden',
        code: 'not_found',
        httpStatus: 404,
      );
    }
    final kit = await store.getKit();
    return PublicHubDto.fromHub(hub, kit: kit);
  }
}
