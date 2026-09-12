import 'package:werkly/features/hub/domain/hub_models.dart';

/// OpenAPI `PublicHub` (edge-functions-v1.yaml) — flat public landing payload.
class PublicHubDto {
  const PublicHubDto({
    required this.slug,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    required this.showBranding,
    required this.links,
    this.mediaKit,
  });

  final String slug;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final bool showBranding;
  final List<PublicHubLinkDto> links;
  final Map<String, dynamic>? mediaKit;

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'display_name': displayName,
        if (bio != null) 'bio': bio,
        'avatar_url': avatarUrl,
        'show_branding': showBranding,
        'links': links.map((l) => l.toJson()).toList(),
        if (mediaKit != null) 'media_kit': mediaKit,
      };

  factory PublicHubDto.fromJson(Map<String, dynamic> j) {
    final linksRaw = j['links'] as List? ?? const [];
    return PublicHubDto(
      slug: (j['slug'] as String?) ?? '',
      displayName: (j['display_name'] ?? j['displayName'] ?? '') as String,
      bio: j['bio'] as String?,
      avatarUrl: (j['avatar_url'] ?? j['avatarUrl']) as String?,
      showBranding: (j['show_branding'] ?? j['showBranding'] ?? true) as bool,
      links: linksRaw
          .map(
            (e) => PublicHubLinkDto.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      mediaKit: j['media_kit'] == null
          ? null
          : Map<String, dynamic>.from(j['media_kit'] as Map),
    );
  }

  /// Map from local [Hub] (+ optional kit) → OpenAPI PublicHub shape.
  factory PublicHubDto.fromHub(Hub hub, {MediaKit? kit}) {
    return PublicHubDto(
      slug: hub.slug,
      displayName: hub.displayName,
      bio: hub.bio.isEmpty ? null : hub.bio,
      avatarUrl: hub.avatarUrl,
      showBranding: hub.showBranding,
      links: hub.orderedLinks
          .where((l) => l.isEnabled)
          .map(PublicHubLinkDto.fromHubLink)
          .toList(),
      mediaKit: kit != null && kit.hubId == hub.id ? kit.toJson() : null,
    );
  }
}

class PublicHubLinkDto {
  const PublicHubLinkDto({
    required this.id,
    required this.type,
    required this.title,
    this.url,
  });

  final String id;
  final String type; // url|social|media_kit|product|tip
  final String title;
  final String? url;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'url': url,
      };

  factory PublicHubLinkDto.fromJson(Map<String, dynamic> j) =>
      PublicHubLinkDto(
        id: j['id'] as String,
        type: (j['type'] as String?) ?? 'url',
        title: (j['title'] ?? j['label'] ?? '') as String,
        url: j['url'] as String?,
      );

  factory PublicHubLinkDto.fromHubLink(HubLink link) => PublicHubLinkDto(
        id: link.id,
        type: link.type.storageValue,
        title: link.label,
        url: link.url,
      );

  HubLinkType get linkType => HubLinkType.fromStorage(type);
}

/// POST track-hub-click body (OpenAPI).
class TrackHubClickRequest {
  const TrackHubClickRequest({
    required this.hubLinkId,
    this.uaHash,
    this.country,
  });

  final String hubLinkId;
  final String? uaHash;
  final String? country;

  Map<String, dynamic> toJson() => {
        'hub_link_id': hubLinkId,
        if (uaHash != null) 'ua_hash': uaHash,
        if (country != null) 'country': country,
      };
}

class HubApiError implements Exception {
  const HubApiError({
    required this.error,
    required this.code,
    required this.httpStatus,
    this.details,
  });

  final String error;
  final String code;
  final int httpStatus;
  final Map<String, dynamic>? details;

  bool get isNotFound => httpStatus == 404 || code == 'not_found';
  bool get isRateLimited => httpStatus == 429 || code == 'rate_limited';

  factory HubApiError.fromJson(
    Map<String, dynamic> j, {
    required int httpStatus,
  }) {
    return HubApiError(
      error: (j['error'] as String?) ?? 'Fehler',
      code: (j['code'] as String?) ?? 'error',
      httpStatus: httpStatus,
      details: j['details'] is Map
          ? Map<String, dynamic>.from(j['details'] as Map)
          : null,
    );
  }

  @override
  String toString() => 'HubApiError($httpStatus $code: $error)';
}
