// F5 Stripe Monetize light — domain.
///
/// Connect status enum matches OpenAPI `StripeConnectStatus`:
/// `none` | `pending` | `active` | `restricted` (never `not_started`).
/// App-Abo (RC `pro`) ≠ Creator-Sales (Stripe).

enum ConnectStatus {
  none,
  pending,
  active,
  restricted;

  /// Storage / OpenAPI / Backend value.
  String get storageValue => name;

  /// DE UI labels (S-50 / S-51).
  String get labelDe => switch (this) {
        ConnectStatus.none => 'Nicht verbunden',
        ConnectStatus.pending => 'In Prüfung',
        ConnectStatus.active => 'Aktiv',
        ConnectStatus.restricted => 'Eingeschränkt',
      };

  String get hintDe => switch (this) {
        ConnectStatus.none =>
          'Verbinde Stripe, bevor du ein Produkt oder Tip live stellst.',
        ConnectStatus.pending =>
          'Onboarding läuft — aktualisiere den Status nach der Rückkehr.',
        ConnectStatus.active =>
          'Auszahlungen aktiv. Checkout und Live-Angebote sind möglich.',
        ConnectStatus.restricted =>
          'Konto eingeschränkt — Onboarding erneut starten oder Stripe prüfen.',
      };

  bool get isActive => this == ConnectStatus.active;
  bool get canCheckout => isActive;
  bool get canGoLive => isActive;
  bool get isNotStarted => this == ConnectStatus.none;

  static ConnectStatus fromStorage(String? v) {
    if (v == null || v.isEmpty) return ConnectStatus.none;
    final lower = v.toLowerCase();
    // Legacy alias from earlier draft — map to OpenAPI `none`.
    if (lower == 'not_started') return ConnectStatus.none;
    return ConnectStatus.values.firstWhere(
      (e) => e.storageValue == lower || e.name == lower,
      orElse: () => ConnectStatus.none,
    );
  }
}

enum SaleKind {
  product,
  tip;

  String get storageValue => name;

  String get labelDe => switch (this) {
        SaleKind.product => 'Produkt',
        SaleKind.tip => 'Tip',
      };

  static SaleKind fromStorage(String? v) {
    if (v == null || v.isEmpty) return SaleKind.product;
    final lower = v.toLowerCase();
    return SaleKind.values.firstWhere(
      (e) => e.storageValue == lower || e.name == lower,
      orElse: () => SaleKind.product,
    );
  }
}

enum SaleStatus {
  pending,
  paid,
  refunded,
  failed;

  String get storageValue => name;

  String get labelDe => switch (this) {
        SaleStatus.pending => 'Offen',
        SaleStatus.paid => 'Bezahlt',
        SaleStatus.refunded => 'Erstattet',
        SaleStatus.failed => 'Fehlgeschlagen',
      };

  static SaleStatus fromStorage(String? v) {
    if (v == null || v.isEmpty) return SaleStatus.paid;
    final lower = v.toLowerCase();
    return SaleStatus.values.firstWhere(
      (e) => e.storageValue == lower || e.name == lower,
      orElse: () => SaleStatus.paid,
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.priceCents,
    this.currency = 'EUR',
    this.unlockUrl,
    this.fileLabel,
    this.live = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// EUR minor units.
  final int priceCents;
  final String currency;

  /// External unlock link after purchase (optional).
  final String? unlockUrl;

  /// Local file label (no upload in MVP mock).
  final String? fileLabel;
  final bool live;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product copyWith({
    String? id,
    String? name,
    int? priceCents,
    String? currency,
    String? unlockUrl,
    String? fileLabel,
    bool? live,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearUnlockUrl = false,
    bool clearFileLabel = false,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      priceCents: priceCents ?? this.priceCents,
      currency: currency ?? this.currency,
      unlockUrl: clearUnlockUrl ? null : (unlockUrl ?? this.unlockUrl),
      fileLabel: clearFileLabel ? null : (fileLabel ?? this.fileLabel),
      live: live ?? this.live,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price_cents': priceCents,
        'currency': currency,
        'unlock_url': unlockUrl,
        'file_label': fileLabel,
        'live': live,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Product.fromJson(Map<String, dynamic> j) {
    return Product(
      id: j['id'] as String,
      name: (j['name'] as String?) ?? '',
      priceCents: (j['price_cents'] ?? j['priceCents'] ?? 0) as int,
      currency: (j['currency'] as String?) ?? 'EUR',
      unlockUrl: (j['unlock_url'] ?? j['unlockUrl']) as String?,
      fileLabel: (j['file_label'] ?? j['fileLabel']) as String?,
      live: (j['live'] as bool?) ?? false,
      createdAt: DateTime.tryParse(
            (j['created_at'] ?? j['createdAt'] ?? '') as String,
          ) ??
          DateTime.now().toUtc(),
      updatedAt: DateTime.tryParse(
            (j['updated_at'] ?? j['updatedAt'] ?? '') as String,
          ) ??
          DateTime.now().toUtc(),
    );
  }
}

class TipLink {
  const TipLink({
    required this.id,
    this.label = 'Tip',
    this.suggestedAmountsCents = const [300, 500, 1000],
    this.live = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String label;

  /// Suggested tip amounts in EUR cents (e.g. 300 / 500 / 1000).
  final List<int> suggestedAmountsCents;
  final bool live;
  final DateTime createdAt;
  final DateTime updatedAt;

  TipLink copyWith({
    String? id,
    String? label,
    List<int>? suggestedAmountsCents,
    bool? live,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TipLink(
      id: id ?? this.id,
      label: label ?? this.label,
      suggestedAmountsCents:
          suggestedAmountsCents ?? this.suggestedAmountsCents,
      live: live ?? this.live,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'suggested_amounts_cents': suggestedAmountsCents,
        'live': live,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory TipLink.fromJson(Map<String, dynamic> j) {
    final raw = j['suggested_amounts_cents'] ??
        j['suggestedAmountsCents'] ??
        const [];
    final amounts = (raw as List).map((e) => (e as num).toInt()).toList();
    return TipLink(
      id: j['id'] as String,
      label: (j['label'] as String?) ?? 'Tip',
      suggestedAmountsCents: amounts.isEmpty ? const [300, 500, 1000] : amounts,
      live: (j['live'] as bool?) ?? false,
      createdAt: DateTime.tryParse(
            (j['created_at'] ?? j['createdAt'] ?? '') as String,
          ) ??
          DateTime.now().toUtc(),
      updatedAt: DateTime.tryParse(
            (j['updated_at'] ?? j['updatedAt'] ?? '') as String,
          ) ??
          DateTime.now().toUtc(),
    );
  }
}

class Sale {
  const Sale({
    required this.id,
    required this.amountCents,
    required this.createdAt,
    this.status = SaleStatus.paid,
    required this.kind,
    this.offerId,
    this.label,
    this.currency = 'EUR',
    this.sessionId,
    this.applicationFeeCents = 0,
    this.feeBps,
  });

  final String id;
  final int amountCents;
  final DateTime createdAt;
  final SaleStatus status;
  final SaleKind kind;

  /// Backend `orders.ref_id`.
  final String? offerId;
  final String? label;
  final String currency;
  final String? sessionId;

  /// From `plan_limits.platform_fee_bps` (Free 1000 / Pro 500).
  final int applicationFeeCents;
  final int? feeBps;

  Sale copyWith({
    String? id,
    int? amountCents,
    DateTime? createdAt,
    SaleStatus? status,
    SaleKind? kind,
    String? offerId,
    String? label,
    String? currency,
    String? sessionId,
    int? applicationFeeCents,
    int? feeBps,
  }) {
    return Sale(
      id: id ?? this.id,
      amountCents: amountCents ?? this.amountCents,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      kind: kind ?? this.kind,
      offerId: offerId ?? this.offerId,
      label: label ?? this.label,
      currency: currency ?? this.currency,
      sessionId: sessionId ?? this.sessionId,
      applicationFeeCents: applicationFeeCents ?? this.applicationFeeCents,
      feeBps: feeBps ?? this.feeBps,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount_cents': amountCents,
        'created_at': createdAt.toIso8601String(),
        'status': status.storageValue,
        'kind': kind.storageValue,
        'offer_id': offerId,
        'label': label,
        'currency': currency,
        'session_id': sessionId,
        'ref_id': offerId,
        'application_fee_cents': applicationFeeCents,
        'fee_bps': feeBps,
      };

  factory Sale.fromJson(Map<String, dynamic> j) {
    return Sale(
      id: j['id'] as String,
      amountCents: (j['amount_cents'] ?? j['amountCents'] ?? 0) as int,
      createdAt: DateTime.tryParse(
            (j['created_at'] ?? j['createdAt'] ?? '') as String,
          ) ??
          DateTime.now().toUtc(),
      status: SaleStatus.fromStorage((j['status'] as String?) ?? 'paid'),
      kind: SaleKind.fromStorage((j['kind'] as String?) ?? 'product'),
      offerId: (j['offer_id'] ?? j['offerId'] ?? j['ref_id'] ?? j['refId']) as String?,
      label: j['label'] as String?,
      currency: (j['currency'] as String?) ?? 'EUR',
      sessionId: (j['session_id'] ?? j['sessionId']) as String?,
      applicationFeeCents:
          (j['application_fee_cents'] ?? j['applicationFeeCents'] ?? 0) as int,
      feeBps: (j['fee_bps'] ?? j['feeBps']) as int?,
    );
  }
}

class MonetizeSnapshot {
  const MonetizeSnapshot({
    required this.connectStatus,
    required this.products,
    required this.tips,
    required this.sales,
  });

  final ConnectStatus connectStatus;
  final List<Product> products;
  final List<TipLink> tips;
  final List<Sale> sales;

  int get liveProductCount => products.where((p) => p.live).length;
  bool get hasLiveTip => tips.any((t) => t.live);
  int get liveOfferCount => liveProductCount + (hasLiveTip ? 1 : 0);
}
