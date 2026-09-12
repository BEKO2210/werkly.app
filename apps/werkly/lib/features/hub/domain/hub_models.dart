/// F3 domain — maps to Backend §2.4 hubs / hub_links / media_kits.

enum HubLinkType {
  url,
  social,
  mediaKit,
  product,
  tip;

  String get storageValue => switch (this) {
        HubLinkType.url => 'url',
        HubLinkType.social => 'social',
        HubLinkType.mediaKit => 'media_kit',
        HubLinkType.product => 'product',
        HubLinkType.tip => 'tip',
      };

  String get label => switch (this) {
        HubLinkType.url => 'URL',
        HubLinkType.social => 'Social',
        HubLinkType.mediaKit => 'Media Kit',
        HubLinkType.product => 'Produkt',
        HubLinkType.tip => 'Tip',
      };

  static HubLinkType fromStorage(String v) {
    return HubLinkType.values.firstWhere(
      (e) => e.storageValue == v || e.name == v,
      orElse: () => HubLinkType.url,
    );
  }
}

class HubLink {
  const HubLink({
    required this.id,
    required this.hubId,
    required this.type,
    required this.label,
    this.url,
    required this.sortOrder,
    this.refId,
    this.isEnabled = true,
  });

  final String id;
  final String hubId;
  final HubLinkType type;
  final String label;
  final String? url;
  final int sortOrder;
  final String? refId;
  final bool isEnabled;

  HubLink copyWith({
    String? id,
    String? hubId,
    HubLinkType? type,
    String? label,
    String? url,
    int? sortOrder,
    String? refId,
    bool? isEnabled,
    bool clearUrl = false,
    bool clearRefId = false,
  }) {
    return HubLink(
      id: id ?? this.id,
      hubId: hubId ?? this.hubId,
      type: type ?? this.type,
      label: label ?? this.label,
      url: clearUrl ? null : (url ?? this.url),
      sortOrder: sortOrder ?? this.sortOrder,
      refId: clearRefId ? null : (refId ?? this.refId),
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hub_id': hubId,
        'type': type.storageValue,
        'label': label,
        'title': label,
        'url': url,
        'sort_order': sortOrder,
        'ref_id': refId,
        'is_enabled': isEnabled,
      };

  factory HubLink.fromJson(Map<String, dynamic> j) => HubLink(
        id: j['id'] as String,
        hubId: (j['hub_id'] ?? j['hubId']) as String,
        type: HubLinkType.fromStorage((j['type'] as String?) ?? 'url'),
        label: (j['label'] ?? j['title'] ?? '') as String,
        url: j['url'] as String?,
        sortOrder: (j['sort_order'] ?? j['sortOrder'] ?? 0) as int,
        refId: (j['ref_id'] ?? j['refId']) as String?,
        isEnabled: (j['is_enabled'] ?? j['isEnabled'] ?? true) as bool,
      );
}

class PlatformFollower {
  const PlatformFollower({
    required this.platform,
    required this.followers,
  });

  final String platform;
  final int followers;

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'followers': followers,
      };

  factory PlatformFollower.fromJson(Map<String, dynamic> j) =>
      PlatformFollower(
        platform: (j['platform'] as String?) ?? '',
        followers: (j['followers'] as num?)?.toInt() ?? 0,
      );
}

class MediaKit {
  const MediaKit({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.hubId,
    this.niches = const [],
    this.platforms = const [],
    this.contactMail,
    this.contactIg,
    this.exampleLinks = const [],
    this.pitch = '',
    this.publicSlug,
    required this.updatedAt,
  });

  final String id;
  final String clientId;
  final String userId;
  final String hubId;
  final List<String> niches;
  final List<PlatformFollower> platforms;
  final String? contactMail;
  final String? contactIg;
  final List<String> exampleLinks;
  final String pitch;
  final String? publicSlug;
  final DateTime updatedAt;

  MediaKit copyWith({
    String? id,
    String? clientId,
    String? userId,
    String? hubId,
    List<String>? niches,
    List<PlatformFollower>? platforms,
    String? contactMail,
    String? contactIg,
    List<String>? exampleLinks,
    String? pitch,
    String? publicSlug,
    DateTime? updatedAt,
    bool clearContactMail = false,
    bool clearContactIg = false,
    bool clearPublicSlug = false,
  }) {
    return MediaKit(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      hubId: hubId ?? this.hubId,
      niches: niches ?? this.niches,
      platforms: platforms ?? this.platforms,
      contactMail:
          clearContactMail ? null : (contactMail ?? this.contactMail),
      contactIg: clearContactIg ? null : (contactIg ?? this.contactIg),
      exampleLinks: exampleLinks ?? this.exampleLinks,
      pitch: pitch ?? this.pitch,
      publicSlug: clearPublicSlug ? null : (publicSlug ?? this.publicSlug),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'user_id': userId,
        'hub_id': hubId,
        'niches': niches,
        'niche': niches,
        'platforms': platforms.map((p) => p.toJson()).toList(),
        'contact_email': contactMail,
        'contact_ig': contactIg,
        'example_links': exampleLinks,
        'pitch': pitch,
        'public_slug': publicSlug,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory MediaKit.fromJson(Map<String, dynamic> j) {
    final nichesRaw = j['niches'] ?? j['niche'] ?? const [];
    final niches = (nichesRaw as List).map((e) => e.toString()).toList();
    final platformsRaw = j['platforms'] as List? ?? const [];
    final linksRaw = j['example_links'] ?? j['exampleLinks'] ?? const [];
    return MediaKit(
      id: j['id'] as String,
      clientId: (j['client_id'] ?? j['clientId'] ?? j['id']) as String,
      userId: (j['user_id'] ?? j['userId'] ?? '') as String,
      hubId: (j['hub_id'] ?? j['hubId']) as String,
      niches: niches,
      platforms: platformsRaw
          .map((e) => PlatformFollower.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      contactMail: (j['contact_email'] ?? j['contactMail']) as String?,
      contactIg: (j['contact_ig'] ?? j['contactIg']) as String?,
      exampleLinks: (linksRaw as List).map((e) => e.toString()).toList(),
      pitch: (j['pitch'] as String?) ?? '',
      publicSlug: (j['public_slug'] ?? j['publicSlug']) as String?,
      updatedAt: DateTime.tryParse(
            (j['updated_at'] ?? j['updatedAt'] ?? '') as String,
          ) ??
          DateTime.now().toUtc(),
    );
  }
}

class Hub {
  const Hub({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.displayName,
    this.bio = '',
    this.avatarUrl,
    required this.slug,
    this.showBranding = true,
    this.isPublic = true,
    this.links = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clientId;
  final String userId;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final String slug;
  final bool showBranding;
  final bool isPublic;
  final List<HubLink> links;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<HubLink> get orderedLinks {
    final copy = List<HubLink>.from(links);
    copy.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return copy;
  }

  Hub copyWith({
    String? id,
    String? clientId,
    String? userId,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? slug,
    bool? showBranding,
    bool? isPublic,
    List<HubLink>? links,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearAvatar = false,
  }) {
    return Hub(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      slug: slug ?? this.slug,
      showBranding: showBranding ?? this.showBranding,
      isPublic: isPublic ?? this.isPublic,
      links: links ?? this.links,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'user_id': userId,
        'display_name': displayName,
        'bio': bio,
        'avatar_url': avatarUrl,
        'slug': slug,
        'show_branding': showBranding,
        'is_public': isPublic,
        'links': orderedLinks.map((l) => l.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Hub.fromJson(Map<String, dynamic> j) {
    final linksRaw = j['links'] as List? ?? const [];
    return Hub(
      id: j['id'] as String,
      clientId: (j['client_id'] ?? j['clientId'] ?? j['id']) as String,
      userId: (j['user_id'] ?? j['userId'] ?? '') as String,
      displayName: (j['display_name'] ?? j['displayName'] ?? '') as String,
      bio: (j['bio'] as String?) ?? '',
      avatarUrl: (j['avatar_url'] ?? j['avatarUrl']) as String?,
      slug: (j['slug'] as String?) ?? 'hub',
      showBranding: (j['show_branding'] ?? j['showBranding'] ?? true) as bool,
      isPublic: (j['is_public'] ?? j['isPublic'] ?? true) as bool,
      links: linksRaw
          .map((e) => HubLink.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
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

/// Fake analytics row for S-34 (Should).
class HubLinkClickStats {
  const HubLinkClickStats({
    required this.linkId,
    required this.label,
    required this.clicks7d,
    required this.clicks30d,
  });

  final String linkId;
  final String label;
  final int clicks7d;
  final int clicks30d;
}
