/// F2 domain entities — maps to Backend §2.3 captions + caption_generations.
enum CaptionKind {
  caption,
  hook;

  String get storageValue => name;

  static CaptionKind fromStorage(String v) {
    return CaptionKind.values.firstWhere(
      (e) => e.name == v,
      orElse: () => CaptionKind.caption,
    );
  }
}

enum CaptionLanguage {
  de,
  en;

  String get label => switch (this) {
        CaptionLanguage.de => 'DE',
        CaptionLanguage.en => 'EN',
      };

  String get storageValue => name;

  static CaptionLanguage fromStorage(String v) {
    return CaptionLanguage.values.firstWhere(
      (e) => e.name == v,
      orElse: () => CaptionLanguage.de,
    );
  }
}

/// Optional platform hint for tone (OpenAPI: ig|tiktok|yt|other).
enum CaptionPlatformHint {
  ig,
  tiktok,
  yt,
  other,
  neutral;

  String get label => switch (this) {
        CaptionPlatformHint.ig => 'IG Reel',
        CaptionPlatformHint.tiktok => 'TikTok',
        CaptionPlatformHint.yt => 'YT',
        CaptionPlatformHint.other => 'Other',
        CaptionPlatformHint.neutral => 'Neutral',
      };

  /// Wire value for Edge API; null when neutral (omit).
  String? get apiValue => switch (this) {
        CaptionPlatformHint.neutral => null,
        CaptionPlatformHint.ig => 'ig',
        CaptionPlatformHint.tiktok => 'tiktok',
        CaptionPlatformHint.yt => 'yt',
        CaptionPlatformHint.other => 'other',
      };

  static CaptionPlatformHint? fromApi(String? v) {
    if (v == null || v.isEmpty) return CaptionPlatformHint.neutral;
    return CaptionPlatformHint.values.firstWhere(
      (e) => e.apiValue == v || e.name == v,
      orElse: () => CaptionPlatformHint.neutral,
    );
  }
}

class CaptionVariant {
  const CaptionVariant({
    required this.id,
    required this.generationId,
    required this.kind,
    required this.body,
    this.isFavorite = false,
  });

  final String id;
  final String generationId;
  final CaptionKind kind;
  final String body;
  final bool isFavorite;

  CaptionVariant copyWith({
    String? id,
    String? generationId,
    CaptionKind? kind,
    String? body,
    bool? isFavorite,
  }) {
    return CaptionVariant(
      id: id ?? this.id,
      generationId: generationId ?? this.generationId,
      kind: kind ?? this.kind,
      body: body ?? this.body,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class CaptionGeneration {
  const CaptionGeneration({
    required this.id,
    required this.prompt,
    required this.language,
    this.tone,
    this.platform,
    required this.variants,
    required this.createdAt,
    this.usedMock = false,
    this.providerNote,
    this.status = 'ok',
  });

  final String id;
  final String prompt;
  final CaptionLanguage language;
  final String? tone;
  final CaptionPlatformHint? platform;
  final List<CaptionVariant> variants;
  final DateTime createdAt;
  final bool usedMock;
  final String? providerNote;
  final String status;

  List<CaptionVariant> get captions =>
      variants.where((v) => v.kind == CaptionKind.caption).toList();

  List<CaptionVariant> get hooks =>
      variants.where((v) => v.kind == CaptionKind.hook).toList();

  CaptionGeneration copyWith({
    List<CaptionVariant>? variants,
    bool? usedMock,
    String? providerNote,
    String? status,
  }) {
    return CaptionGeneration(
      id: id,
      prompt: prompt,
      language: language,
      tone: tone,
      platform: platform,
      variants: variants ?? this.variants,
      createdAt: createdAt,
      usedMock: usedMock ?? this.usedMock,
      providerNote: providerNote ?? this.providerNote,
      status: status ?? this.status,
    );
  }
}

/// Saved favorite (Should US-F2-04).
class Favorite {
  const Favorite({
    required this.id,
    required this.body,
    required this.kind,
    this.language,
    this.sourceVariantId,
    this.sourceGenerationId,
    required this.createdAt,
  });

  final String id;
  final String body;
  final CaptionKind kind;
  final CaptionLanguage? language;
  final String? sourceVariantId;
  final String? sourceGenerationId;
  final DateTime createdAt;
}

/// Prefill payload for PostEditor deep-link (F2 → F1).
class CaptionPrefill {
  const CaptionPrefill({
    required this.captionPrefill,
    this.platformHint,
  });

  final String captionPrefill;
  final CaptionPlatformHint? platformHint;
}

/// Quota snapshot returned with generations (OpenAPI).
class CaptionQuotaSnapshot {
  const CaptionQuotaSnapshot({
    required this.used,
    required this.limit,
    required this.plan,
    required this.period,
  });

  final int used;
  final int limit;
  final String plan; // free | pro
  /// UTC calendar month `YYYY-MM` (GENERATE-CAPTION-V1).
  final String period;

  factory CaptionQuotaSnapshot.fromJson(Map<String, dynamic> json) {
    return CaptionQuotaSnapshot(
      used: json['used'] as int? ?? 0,
      limit: json['limit'] as int? ?? 10,
      plan: json['plan'] as String? ?? 'free',
      period: json['period'] as String? ?? CaptionQuotaSnapshot.currentPeriodUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'used': used,
        'limit': limit,
        'plan': plan,
        'period': period,
      };

  static String currentPeriodUtc([DateTime? now]) {
    final n = now ?? DateTime.now().toUtc();
    final m = n.month.toString().padLeft(2, '0');
    return '${n.year}-$m';
  }
}

/// Wire DTO matching contracts/mocks/generate-caption-200*.json
class GenerateCaptionResponse {
  const GenerateCaptionResponse({
    required this.generationId,
    required this.captions,
    required this.hooks,
    required this.quota,
  });

  final String generationId;
  final List<CaptionVariantDto> captions;
  final List<CaptionVariantDto> hooks;
  final CaptionQuotaSnapshot quota;

  factory GenerateCaptionResponse.fromJson(Map<String, dynamic> json) {
    return GenerateCaptionResponse(
      generationId: json['generation_id'] as String,
      captions: (json['captions'] as List<dynamic>)
          .map((e) => CaptionVariantDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      hooks: (json['hooks'] as List<dynamic>)
          .map((e) => CaptionVariantDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      quota: CaptionQuotaSnapshot.fromJson(
        json['quota'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'generation_id': generationId,
        'captions': captions.map((e) => e.toJson()).toList(),
        'hooks': hooks.map((e) => e.toJson()).toList(),
        'quota': quota.toJson(),
      };
}

class CaptionVariantDto {
  const CaptionVariantDto({
    required this.id,
    required this.kind,
    required this.body,
  });

  final String id;
  final String kind;
  final String body;

  factory CaptionVariantDto.fromJson(Map<String, dynamic> json) {
    return CaptionVariantDto(
      id: json['id'] as String,
      kind: json['kind'] as String,
      body: json['body'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'body': body,
      };

  CaptionVariant toDomain({required String generationId}) {
    return CaptionVariant(
      id: id,
      generationId: generationId,
      kind: CaptionKind.fromStorage(kind),
      body: body,
    );
  }
}

/// API / mock error body (400/402/…).
class CaptionApiError {
  const CaptionApiError({
    required this.error,
    required this.code,
    this.details,
    this.httpStatus,
  });

  final String error;
  final String code;
  final Map<String, dynamic>? details;
  final int? httpStatus;

  factory CaptionApiError.fromJson(
    Map<String, dynamic> json, {
    int? httpStatus,
  }) {
    return CaptionApiError(
      error: json['error'] as String? ?? 'Unbekannter Fehler',
      code: json['code'] as String? ?? 'server_error',
      details: json['details'] as Map<String, dynamic>?,
      httpStatus: httpStatus,
    );
  }

  bool get isQuotaExceeded => code == 'quota_exceeded' || httpStatus == 402;
  bool get isPolicyReject => code == 'policy_reject';

  String? get paywallTrigger =>
      details?['paywall_trigger'] as String? ??
      (isQuotaExceeded ? 'limit_captions' : null);
}

class GenerateCaptionRequest {
  const GenerateCaptionRequest({
    required this.prompt,
    required this.language,
    this.tone,
    this.platform,
  });

  final String prompt;
  final CaptionLanguage language;
  final String? tone;
  final CaptionPlatformHint? platform;

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'language': language.storageValue,
        if (tone != null && tone!.trim().isNotEmpty) 'tone': tone!.trim(),
        if (platform?.apiValue != null) 'platform': platform!.apiValue,
      };
}
