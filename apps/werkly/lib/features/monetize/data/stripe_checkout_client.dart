import 'dart:convert';

import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/captions/data/edge_caption_client.dart';
import 'package:werkly/features/monetize/data/local_monetize_repository.dart';
import 'package:werkly/features/monetize/data/monetize_memory_store.dart';
import 'package:werkly/features/monetize/domain/monetize_models.dart';
import 'package:werkly/features/monetize/domain/monetize_validation.dart';
import 'package:werkly/features/monetize/domain/stripe_api.dart';

/// Edge `POST /functions/v1/stripe-checkout`.
///
/// 403 `connect_inactive` → S-51; 402 `quota_exceeded` → `limit_stripe_products`.
/// Mock checkout URL when Edge is not configured. No Stripe secrets.
class StripeCheckoutClient {
  StripeCheckoutClient({
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

  Uri get _endpoint {
    final root = baseUrl!.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$root/functions/v1/stripe-checkout');
  }

  /// Create hosted Checkout Session. Records a local mock sale on 200.
  Future<CheckoutResponse> checkout({
    required CheckoutRequest request,
    required bool isPro,
    bool recordSale = true,
  }) async {
    _assertTipAmount(request);
    if (isConfigured) {
      try {
        final res = await _postEdge(request);
        if (recordSale) {
          await _recordMockSale(request, res, isPro: isPro);
        }
        return res;
      } on StripeApiError {
        rethrow;
      } catch (_) {
        return _localCheckout(request, isPro: isPro, recordSale: recordSale);
      }
    }
    return _localCheckout(request, isPro: isPro, recordSale: recordSale);
  }

  void _assertTipAmount(CheckoutRequest request) {
    if (request.kind == SaleKind.tip &&
        !MonetizeValidation.tipCheckoutAmountOk(request.tipAmountCents)) {
      throw StripeApiError.fromJson(
        StripeMockFixtures.checkout400,
        httpStatus: 400,
      );
    }
  }

  Future<CheckoutResponse> _postEdge(CheckoutRequest request) async {
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
        uri: _endpoint,
        headers: headers,
        body: jsonEncode(request.toJson()),
      ),
    );
    final decoded = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return CheckoutResponse.fromJson(decoded, source: 'edge');
    }
    throw StripeApiError.fromJson(decoded, httpStatus: res.statusCode);
  }

  Future<CheckoutResponse> _localCheckout(
    CheckoutRequest request, {
    required bool isPro,
    required bool recordSale,
  }) async {
    final store = _store;
    final status = store == null
        ? ConnectStatus.none
        : await store.connectStatus();
    if (!status.canCheckout) {
      throw StripeApiError.fromJson(
        {
          ...StripeMockFixtures.checkout403,
          'details': {
            'stripe_connect_status': status.storageValue,
            'hint': 'S-51 Onboarding abschließen',
          },
        },
        httpStatus: 403,
      );
    }

    if (store != null) {
      final products = await store.products();
      final tips = await store.tips();
      if (request.kind == SaleKind.product) {
        final match = products.where((p) => p.id == request.id);
        if (match.isEmpty) {
          throw const StripeApiError(
            error: 'Produkt nicht gefunden',
            code: 'bad_request',
            httpStatus: 400,
          );
        }
        if (!isPro) {
          final liveOthers =
              products.where((p) => p.live && p.id != request.id).length;
          final tipLive = tips.any((t) => t.live);
          if (liveOthers + (tipLive ? 1 : 0) >= QuotaPolicy.freeLiveOffers &&
              !match.first.live) {
            throw StripeApiError.fromJson(
              StripeMockFixtures.checkout402,
              httpStatus: 402,
            );
          }
        }
      }
    }

    final res = CheckoutResponse.fromJson(
      StripeMockFixtures.checkoutOk,
      source: 'mock',
    );
    if (recordSale) {
      await _recordMockSale(request, res, isPro: isPro);
    }
    return res;
  }

  Future<void> _recordMockSale(
    CheckoutRequest request,
    CheckoutResponse res, {
    bool isPro = false,
  }) async {
    final store = _store;
    if (store == null) return;
    final repo = LocalMonetizeRepository(store: store);
    int amount = request.tipAmountCents ?? 0;
    String? label;
    if (request.kind == SaleKind.product) {
      final p = await store.productById(request.id);
      amount = p?.priceCents ?? amount;
      label = p?.name;
    } else {
      final t = await store.tipById(request.id);
      label = t?.label ?? 'Tip';
    }
    if (amount <= 0) amount = 500;
    await repo.simulateSale(
      kind: request.kind,
      amountCents: amount,
      offerId: request.id,
      label: label,
      sessionId: res.sessionId,
      isPro: isPro,
    );
  }
}
