import 'dart:convert';

import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/captions/data/edge_caption_client.dart';
import 'package:werkly/features/monetize/data/monetize_memory_store.dart';
import 'package:werkly/features/monetize/domain/monetize_models.dart';
import 'package:werkly/features/monetize/domain/stripe_api.dart';

/// Backend `GET /orders` — Creator read-only (RLS select; webhook writes).
///
/// Scaffold: local [MonetizeMemoryStore] sales as orders. No INSERT from client
/// except mock simulate (stands in for `checkout.session.completed`).
class OrdersClient {
  OrdersClient({
    MonetizeMemoryStore? store,
    this.baseUrl,
    this.accessTokenProvider,
    Future<EdgeHttpResponse> Function(Uri uri, Map<String, String> headers)?
        httpGet,
  })  : _store = store,
        _httpGet = httpGet;

  MonetizeMemoryStore? _store;
  final String? baseUrl;
  final Future<String?> Function()? accessTokenProvider;
  final Future<EdgeHttpResponse> Function(Uri uri, Map<String, String> headers)?
      _httpGet;

  void bindStore(MonetizeMemoryStore store) => _store = store;

  bool get isConfigured =>
      WerklySupabase.isConfigured &&
      baseUrl != null &&
      baseUrl!.isNotEmpty &&
      _httpGet != null;

  Uri get _endpoint {
    final root = baseUrl!.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$root/rest/v1/orders?select=*&order=created_at.desc');
  }

  /// GET-only. Never writes orders (webhook / mock simulate does).
  Future<List<Sale>> listOrders() async {
    if (isConfigured) {
      try {
        return await _fetchEdge();
      } catch (_) {
        return _local();
      }
    }
    return _local();
  }

  Future<List<Sale>> _fetchEdge() async {
    final token = await (accessTokenProvider?.call() ?? Future.value(null));
    if (token == null || token.isEmpty) {
      throw const StripeApiError(
        error: 'Nicht angemeldet',
        code: 'unauthorized',
        httpStatus: 401,
      );
    }
    final res = await _httpGet!(_endpoint, {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'X-Werkly-Mock': '1',
    });
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StripeApiError(
        error: 'Orders nicht erreichbar',
        code: 'upstream_unavailable',
        httpStatus: res.statusCode,
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is List) {
      return decoded
          .map((e) => Sale.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return const [];
  }

  Future<List<Sale>> _local() async {
    final store = _store;
    if (store == null) return const [];
    return store.sales();
  }
}
