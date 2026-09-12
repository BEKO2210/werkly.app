import 'dart:convert';

import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/captions/data/edge_caption_client.dart';
import 'package:werkly/features/deals/data/deal_memory_store.dart';
import 'package:werkly/features/deals/domain/deal_csv.dart';
import 'package:werkly/features/deals/domain/deals_export_api.dart';

/// Edge `GET /functions/v1/deals-export` (OpenAPI operationId: dealsExport).
///
/// Pro-only on Edge (402 when Free). When Supabase is not configured,
/// falls back to local [DealCsv.generate] from [DealMemoryStore] (same columns).
class DealsExportClient {
  DealsExportClient({
    DealMemoryStore? store,
    this.baseUrl,
    this.accessTokenProvider,
    Future<EdgeHttpResponse> Function(Uri uri, Map<String, String> headers)?
        httpGet,
  })  : _store = store,
        _httpGet = httpGet;

  DealMemoryStore? _store;
  final String? baseUrl;
  final Future<String?> Function()? accessTokenProvider;
  final Future<EdgeHttpResponse> Function(Uri uri, Map<String, String> headers)?
      _httpGet;

  void bindStore(DealMemoryStore store) => _store = store;

  bool get isConfigured =>
      WerklySupabase.isConfigured &&
      baseUrl != null &&
      baseUrl!.isNotEmpty &&
      _httpGet != null;

  Uri get _endpoint {
    final root = baseUrl!.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$root/functions/v1/deals-export');
  }

  /// Returns CSV payload. Prefer Edge when configured; else local fallback.
  Future<DealsExportResponse> export({required bool isPro}) async {
    if (!isPro) {
      throw const DealsExportApiError(
        error: 'CSV-Export ist Teil von Werkly Pro',
        code: 'payment_required',
        httpStatus: 402,
      );
    }
    if (isConfigured) {
      try {
        return await _fetchEdge();
      } catch (_) {
        // Soft fallback to local CSV so Pro still works offline.
        return _localFallback();
      }
    }
    return _localFallback();
  }

  Future<DealsExportResponse> _fetchEdge() async {
    final token = await (accessTokenProvider?.call() ?? Future.value(null));
    if (token == null || token.isEmpty) {
      throw const DealsExportApiError(
        error: 'Nicht angemeldet',
        code: 'unauthorized',
        httpStatus: 401,
      );
    }
    final headers = <String, String>{
      'Accept': 'application/json, text/csv',
      'Authorization': 'Bearer $token',
    };
    final EdgeHttpResponse res;
    try {
      res = await _httpGet!(_endpoint, headers);
    } catch (e) {
      throw DealsExportApiError(
        error: 'Export nicht erreichbar',
        code: 'upstream_unavailable',
        httpStatus: 503,
        details: {'cause': e.toString()},
      );
    }

    if (res.statusCode == 402) {
      throw const DealsExportApiError(
        error: 'CSV-Export ist Teil von Werkly Pro',
        code: 'payment_required',
        httpStatus: 402,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      Map<String, dynamic> decoded = {};
      try {
        if (res.body.isNotEmpty && res.body.trimLeft().startsWith('{')) {
          decoded = jsonDecode(res.body) as Map<String, dynamic>;
        }
      } catch (_) {}
      throw DealsExportApiError.fromJson(decoded, httpStatus: res.statusCode);
    }

    // Edge may return JSON {csv,...} or raw CSV body.
    final body = res.body;
    if (body.trimLeft().startsWith('{')) {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final dto = DealsExportResponse.fromJson(map);
      return DealsExportResponse(
        csv: dto.csv,
        contentType: dto.contentType,
        rowCount: dto.rowCount,
        source: 'edge',
      );
    }
    final lines = body.trimRight().split('\n');
    return DealsExportResponse(
      csv: body.endsWith('\n') ? body : '$body\n',
      contentType: 'text/csv',
      rowCount: lines.length > 1 ? lines.length - 1 : 0,
      source: 'edge',
    );
  }

  Future<DealsExportResponse> _localFallback() async {
    final store = _store;
    if (store == null) {
      return const DealsExportResponse(csv: '', rowCount: 0, source: 'local');
    }
    final deals = await store.all();
    final csv = DealCsv.generate(deals);
    final rows = deals.length;
    return DealsExportResponse(
      csv: csv,
      contentType: 'text/csv',
      rowCount: rows,
      source: 'local',
    );
  }
}
