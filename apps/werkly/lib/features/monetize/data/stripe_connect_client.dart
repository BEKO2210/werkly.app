import 'dart:convert';

import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/captions/data/edge_caption_client.dart';
import 'package:werkly/features/monetize/data/monetize_memory_store.dart';
import 'package:werkly/features/monetize/domain/monetize_models.dart';
import 'package:werkly/features/monetize/domain/stripe_api.dart';

/// Edge `POST /functions/v1/stripe-connect-onboard`.
///
/// When [WerklySupabase.isConfigured] is false, returns mock
/// `https://connect.stripe.com/...` fixtures (X-Werkly-Mock / local).
/// No Stripe secrets in this client.
class StripeConnectClient {
  StripeConnectClient({
    MonetizeMemoryStore? store,
    this.baseUrl,
    this.accessTokenProvider,
    this.mockHeader = true,
    Future<EdgeHttpResponse> Function(EdgeHttpRequest request)? httpPost,
  })  : _store = store,
        _httpPost = httpPost;

  MonetizeMemoryStore? _store;
  final String? baseUrl;
  final Future<String?> Function()? accessTokenProvider;
  final bool mockHeader;
  final Future<EdgeHttpResponse> Function(EdgeHttpRequest request)? _httpPost;

  void bindStore(MonetizeMemoryStore store) => _store = store;

  bool get isConfigured =>
      WerklySupabase.isConfigured &&
      baseUrl != null &&
      baseUrl!.isNotEmpty &&
      _httpPost != null;

  Uri get _onboardEndpoint {
    final root = baseUrl!.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$root/functions/v1/stripe-connect-onboard');
  }

  Uri get _statusEndpoint {
    final root = baseUrl!.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$root/functions/v1/stripe-connect-status');
  }

  /// Start / continue Express onboarding. Returns hosted Account Link URL.
  Future<ConnectOnboardResponse> startOnboard({
    ConnectOnboardRequest request = const ConnectOnboardRequest(),
  }) async {
    if (isConfigured) {
      try {
        return await _postOnboard(request);
      } catch (_) {
        return _localOnboard();
      }
    }
    return _localOnboard();
  }

  /// Refresh status after return from hosted onboarding.
  /// Mock: pending → active (dev, no real Stripe).
  Future<ConnectStatus> refreshStatus() async {
    final store = _store;
    if (isConfigured && _httpPost != null) {
      try {
        return await _fetchEdgeStatus();
      } catch (_) {
        // Fall through to local.
      }
    }
    if (store == null) return ConnectStatus.none;
    final current = await store.connectStatus();
    if (current == ConnectStatus.pending) {
      return store.setConnectStatus(ConnectStatus.active);
    }
    return current;
  }

  Future<ConnectOnboardResponse> _postOnboard(
    ConnectOnboardRequest request,
  ) async {
    final token = await (accessTokenProvider?.call() ?? Future.value(null));
    if (token == null || token.isEmpty) {
      throw const StripeApiError(
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
    final res = await _httpPost!(
      EdgeHttpRequest(
        uri: _onboardEndpoint,
        headers: headers,
        body: jsonEncode(request.toJson()),
      ),
    );
    final decoded = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final dto = ConnectOnboardResponse.fromJson(decoded);
      await _store?.setConnectStatus(dto.stripeConnectStatus);
      return dto;
    }
    throw StripeApiError.fromJson(decoded, httpStatus: res.statusCode);
  }

  Future<ConnectStatus> _fetchEdgeStatus() async {
    final token = await (accessTokenProvider?.call() ?? Future.value(null));
    if (token == null || token.isEmpty) {
      throw const StripeApiError(
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
    final res = await _httpPost!(
      EdgeHttpRequest(
        uri: _statusEndpoint,
        headers: headers,
        body: '{}',
      ),
    );
    final decoded = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final status = ConnectStatus.fromStorage(
        (decoded['stripe_connect_status'] ?? decoded['stripeConnectStatus'])
            as String?,
      );
      await _store?.setConnectStatus(status);
      return status;
    }
    throw StripeApiError.fromJson(decoded, httpStatus: res.statusCode);
  }

  Future<ConnectOnboardResponse> _localOnboard() async {
    final store = _store;
    final current = store == null
        ? ConnectStatus.none
        : await store.connectStatus();
    if (current == ConnectStatus.active) {
      return ConnectOnboardResponse.fromJson(StripeMockFixtures.onboardActive);
    }
    await store?.setConnectStatus(ConnectStatus.pending);
    return ConnectOnboardResponse.fromJson(StripeMockFixtures.onboardPending);
  }
}
