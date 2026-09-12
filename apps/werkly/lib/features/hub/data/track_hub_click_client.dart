import 'dart:convert';

import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/captions/data/edge_caption_client.dart';
import 'package:werkly/features/hub/data/hub_memory_store.dart';
import 'package:werkly/features/hub/domain/public_hub_api.dart';

/// Edge `POST /functions/v1/track-hub-click` (OpenAPI operationId: trackHubClick).
///
/// Local mock increments in-memory click counters for S-34 analytics.
class TrackHubClickClient {
  TrackHubClickClient({
    HubMemoryStore? store,
    this.baseUrl,
    Future<EdgeHttpResponse> Function(EdgeHttpRequest request)? httpPost,
  })  : _store = store,
        _httpPost = httpPost;

  HubMemoryStore? _store;
  final String? baseUrl;
  final Future<EdgeHttpResponse> Function(EdgeHttpRequest request)? _httpPost;

  void bindStore(HubMemoryStore store) => _store = store;

  bool get isConfigured =>
      WerklySupabase.isConfigured &&
      baseUrl != null &&
      baseUrl!.isNotEmpty &&
      _httpPost != null;

  Uri get _endpoint {
    final root = baseUrl!.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$root/functions/v1/track-hub-click');
  }

  /// Records a click. Success = HTTP 204 (no body). Throws [HubApiError] on 404/429.
  Future<void> track(TrackHubClickRequest request) async {
    if (isConfigured) {
      await _trackEdge(request);
      return;
    }
    await _trackLocalMock(request);
  }

  Future<void> _trackEdge(TrackHubClickRequest request) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode(request.toJson());
    final EdgeHttpResponse res;
    try {
      res = await _httpPost!(
        EdgeHttpRequest(uri: _endpoint, headers: headers, body: body),
      );
    } catch (e) {
      throw HubApiError(
        error: 'Klick-Tracking nicht erreichbar',
        code: 'upstream_unavailable',
        httpStatus: 503,
        details: {'cause': e.toString()},
      );
    }
    if (res.statusCode == 204 ||
        (res.statusCode >= 200 && res.statusCode < 300)) {
      return;
    }
    final decoded = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    throw HubApiError.fromJson(decoded, httpStatus: res.statusCode);
  }

  Future<void> _trackLocalMock(TrackHubClickRequest request) async {
    final store = _store;
    if (store == null) {
      throw const HubApiError(
        error: 'Link nicht gefunden',
        code: 'not_found',
        httpStatus: 404,
      );
    }
    final hub = await store.getHub();
    if (hub == null ||
        !hub.links.any((l) => l.id == request.hubLinkId && l.isEnabled)) {
      throw const HubApiError(
        error: 'Link nicht gefunden',
        code: 'not_found',
        httpStatus: 404,
      );
    }
    await store.recordClick(request.hubLinkId);
  }
}
