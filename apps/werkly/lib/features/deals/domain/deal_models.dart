/// F4 Deal-Tracker domain — Backend `deals` table (local + optional sync stub).
///
/// Soft-delete via [deletedAt]; open = status ≠ invoiced|lost.
/// Amounts: [amountCents] + currency EUR.

/// Pipeline enums aligned with Backend:
/// inquiry / negotiation / won / invoiced / lost
/// DE UI: Anfrage → Verhandlung → Gewonnen → Abgerechnet / Verloren
enum DealStatus {
  inquiry,
  negotiation,
  won,
  invoiced,
  lost;

  /// Storage / API / Backend enum value.
  String get storageValue => name;

  /// DE UI labels (US-F4-01).
  String get labelDe => switch (this) {
        DealStatus.inquiry => 'Anfrage',
        DealStatus.negotiation => 'Verhandlung',
        DealStatus.won => 'Gewonnen',
        DealStatus.invoiced => 'Abgerechnet',
        DealStatus.lost => 'Verloren',
      };

  /// Open = status ≠ invoiced|lost → inquiry|negotiation|won
  bool get isOpen =>
      this != DealStatus.invoiced && this != DealStatus.lost;

  static DealStatus fromStorage(String? v) {
    if (v == null || v.isEmpty) return DealStatus.inquiry;
    final lower = v.toLowerCase();
    return DealStatus.values.firstWhere(
      (e) => e.storageValue == lower || e.name == lower,
      orElse: () {
        return switch (lower) {
          'anfrage' => DealStatus.inquiry,
          'verhandlung' => DealStatus.negotiation,
          'gewonnen' => DealStatus.won,
          'abgerechnet' => DealStatus.invoiced,
          'verloren' => DealStatus.lost,
          _ => DealStatus.inquiry,
        };
      },
    );
  }

  static const pipeline = [
    DealStatus.inquiry,
    DealStatus.negotiation,
    DealStatus.won,
    DealStatus.invoiced,
    DealStatus.lost,
  ];
}

class Deal {
  const Deal({
    required this.id,
    required this.clientId,
    required this.brand,
    required this.title,
    this.amountCents,
    this.currency = 'EUR',
    this.status = DealStatus.inquiry,
    this.dueAt,
    this.notes,
    this.hubId,
    this.mediaKitId,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String clientId;
  final String brand;
  final String title;

  /// Backend `amount_cents` (EUR minor units).
  final int? amountCents;
  final String currency;
  final DealStatus status;
  final DateTime? dueAt;
  final String? notes;
  final String? hubId;
  final String? mediaKitId;
  final DateTime updatedAt;

  /// Soft-delete timestamp (Backend `deleted_at`); null = active.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
  bool get isOpen => !isDeleted && status.isOpen;

  Deal copyWith({
    String? id,
    String? clientId,
    String? brand,
    String? title,
    int? amountCents,
    String? currency,
    DealStatus? status,
    DateTime? dueAt,
    String? notes,
    String? hubId,
    String? mediaKitId,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearAmount = false,
    bool clearDueAt = false,
    bool clearNotes = false,
    bool clearHubId = false,
    bool clearMediaKitId = false,
    bool clearDeletedAt = false,
  }) {
    return Deal(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      brand: brand ?? this.brand,
      title: title ?? this.title,
      amountCents: clearAmount ? null : (amountCents ?? this.amountCents),
      currency: currency ?? this.currency,
      status: status ?? this.status,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      notes: clearNotes ? null : (notes ?? this.notes),
      hubId: clearHubId ? null : (hubId ?? this.hubId),
      mediaKitId: clearMediaKitId ? null : (mediaKitId ?? this.mediaKitId),
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'brand': brand,
        'title': title,
        'amount_cents': amountCents,
        'currency': currency,
        'status': status.storageValue,
        'due_at': dueAt?.toIso8601String(),
        'notes': notes,
        'hub_id': hubId,
        'media_kit_id': mediaKitId,
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  factory Deal.fromJson(Map<String, dynamic> j) {
    return Deal(
      id: j['id'] as String,
      clientId: (j['client_id'] ?? j['clientId'] ?? j['id']) as String,
      brand: (j['brand'] as String?) ?? '',
      title: (j['title'] as String?) ?? '',
      amountCents: (j['amount_cents'] ?? j['amountCents']) as int?,
      currency: (j['currency'] as String?) ?? 'EUR',
      status: DealStatus.fromStorage(
        (j['status'] as String?) ?? 'inquiry',
      ),
      dueAt: DateTime.tryParse(
        (j['due_at'] ?? j['dueAt'] ?? '') as String,
      ),
      notes: j['notes'] as String?,
      hubId: (j['hub_id'] ?? j['hubId']) as String?,
      mediaKitId: (j['media_kit_id'] ?? j['mediaKitId']) as String?,
      updatedAt: DateTime.tryParse(
            (j['updated_at'] ?? j['updatedAt'] ?? '') as String,
          ) ??
          DateTime.now().toUtc(),
      deletedAt: DateTime.tryParse(
        (j['deleted_at'] ?? j['deletedAt'] ?? '') as String,
      ),
    );
  }
}
