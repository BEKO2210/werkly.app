import 'package:werkly/features/monetize/domain/monetize_models.dart';

/// OpenAPI `POST /stripe-connect-onboard` request.
class ConnectOnboardRequest {
  const ConnectOnboardRequest({
    this.returnUrl = 'werkly://stripe/return',
    this.refreshUrl = 'werkly://stripe/refresh',
  });

  final String? returnUrl;
  final String? refreshUrl;

  Map<String, dynamic> toJson() => {
        if (returnUrl != null) 'return_url': returnUrl,
        if (refreshUrl != null) 'refresh_url': refreshUrl,
      };
}

/// OpenAPI 200 `{ url, stripe_connect_status }`.
class ConnectOnboardResponse {
  const ConnectOnboardResponse({
    required this.url,
    required this.stripeConnectStatus,
  });

  final String url;
  final ConnectStatus stripeConnectStatus;

  factory ConnectOnboardResponse.fromJson(Map<String, dynamic> j) {
    return ConnectOnboardResponse(
      url: (j['url'] as String?) ?? '',
      stripeConnectStatus: ConnectStatus.fromStorage(
        (j['stripe_connect_status'] ?? j['stripeConnectStatus']) as String?,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'stripe_connect_status': stripeConnectStatus.storageValue,
      };
}

/// OpenAPI `CheckoutRequest` — `POST /stripe-checkout`.
class CheckoutRequest {
  const CheckoutRequest({
    required this.kind,
    required this.id,
    this.tipAmountCents,
    this.successUrl,
    this.cancelUrl,
  });

  final SaleKind kind;
  final String id;

  /// Required when [kind] is tip; minimum 100 (1,00 €).
  final int? tipAmountCents;
  final String? successUrl;
  final String? cancelUrl;

  Map<String, dynamic> toJson() => {
        'kind': kind.storageValue,
        'id': id,
        if (tipAmountCents != null) 'tip_amount_cents': tipAmountCents,
        if (successUrl != null) 'success_url': successUrl,
        if (cancelUrl != null) 'cancel_url': cancelUrl,
      };

  factory CheckoutRequest.fromJson(Map<String, dynamic> j) {
    return CheckoutRequest(
      kind: SaleKind.fromStorage(j['kind'] as String?),
      id: (j['id'] as String?) ?? '',
      tipAmountCents: (j['tip_amount_cents'] ?? j['tipAmountCents']) as int?,
      successUrl: (j['success_url'] ?? j['successUrl']) as String?,
      cancelUrl: (j['cancel_url'] ?? j['cancelUrl']) as String?,
    );
  }
}

/// OpenAPI 200 `{ url, session_id? }`.
class CheckoutResponse {
  const CheckoutResponse({
    required this.url,
    this.sessionId,
    this.source = 'mock',
  });

  final String url;
  final String? sessionId;

  /// `edge` | `mock` — which path produced the URL.
  final String source;

  factory CheckoutResponse.fromJson(
    Map<String, dynamic> j, {
    String source = 'edge',
  }) {
    return CheckoutResponse(
      url: (j['url'] as String?) ?? '',
      sessionId: (j['session_id'] ?? j['sessionId']) as String?,
      source: (j['source'] as String?) ?? source,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        if (sessionId != null) 'session_id': sessionId,
        'source': source,
      };
}

/// Edge / mock error — 400 validation, 402 quota, 403 connect_inactive.
class StripeApiError implements Exception {
  const StripeApiError({
    required this.error,
    this.code = 'upstream_unavailable',
    this.httpStatus = 503,
    this.details,
  });

  final String error;
  final String code;
  final int httpStatus;
  final Map<String, dynamic>? details;

  bool get isBadRequest => httpStatus == 400;
  bool get isQuotaExceeded => httpStatus == 402 || code == 'quota_exceeded';
  bool get isConnectInactive =>
      httpStatus == 403 || code == 'connect_inactive';
  bool get isUnauthorized => httpStatus == 401;

  String? get paywallTrigger {
    final d = details;
    if (d == null) return isQuotaExceeded ? 'limit_stripe_products' : null;
    return (d['paywall_trigger'] ?? d['paywallTrigger']) as String?;
  }

  ConnectStatus? get connectStatusHint {
    final d = details;
    if (d == null) return null;
    final v = d['stripe_connect_status'] ?? d['stripeConnectStatus'];
    if (v is String) return ConnectStatus.fromStorage(v);
    return null;
  }

  factory StripeApiError.fromJson(
    Map<String, dynamic> j, {
    required int httpStatus,
  }) {
    return StripeApiError(
      error: (j['error'] as String?) ?? 'Stripe-Anfrage fehlgeschlagen',
      code: (j['code'] as String?) ?? 'error',
      httpStatus: httpStatus,
      details: j['details'] is Map
          ? Map<String, dynamic>.from(j['details'] as Map)
          : null,
    );
  }

  @override
  String toString() => 'StripeApiError($httpStatus $code: $error)';
}

/// Built-in fixture shapes (same as `assets/contracts/mocks/stripe-*.json`).
/// Used when Edge is not configured — no Stripe secrets.
abstract final class StripeMockFixtures {
  static const mockConnectUrl =
      'https://connect.stripe.com/setup/e/acct_mock_werkly/test_onboard';
  static const mockConnectRefreshUrl =
      'https://connect.stripe.com/setup/e/acct_mock_werkly/test_refresh';
  static const mockCheckoutUrl =
      'https://checkout.stripe.com/c/pay/cs_test_mock_werkly';
  static const mockSessionId = 'cs_test_mock_werkly';

  static const onboardPending = {
    'url': mockConnectUrl,
    'stripe_connect_status': 'pending',
  };

  static const onboardActive = {
    'url': mockConnectRefreshUrl,
    'stripe_connect_status': 'active',
  };

  static const checkoutOk = {
    'url': mockCheckoutUrl,
    'session_id': mockSessionId,
  };

  static const checkout400 = {
    'error': 'tip_amount_cents erforderlich wenn kind=tip',
    'code': 'bad_request',
    'details': {
      'field': 'tip_amount_cents',
      'minimum': 100,
    },
  };

  static const checkout402 = {
    'error': 'Produkt-Kontingent erreicht (Free: Tip oder 1 Produkt)',
    'code': 'quota_exceeded',
    'details': {
      'used': 1,
      'limit': 1,
      'plan': 'free',
      'paywall_trigger': 'limit_stripe_products',
    },
  };

  static const checkout403 = {
    'error': 'Stripe Connect ist noch nicht aktiv',
    'code': 'connect_inactive',
    'details': {
      'stripe_connect_status': 'pending',
      'hint': 'S-51 Onboarding abschließen',
    },
  };
}
