/// F1 domain entity — maps to Drift `calendar_posts` + Supabase §2.2.
class CalendarPost {
  const CalendarPost({
    required this.id,
    required this.clientId,
    this.title,
    this.captionStub,
    required this.platforms,
    required this.scheduledAt,
    required this.status,
    required this.reminderOffsetMinutes,
    required this.updatedAt,
    this.syncPending = true,
  });

  final String id;
  final String clientId;
  final String? title;
  final String? captionStub;
  final Set<PostPlatform> platforms;
  final DateTime scheduledAt;
  final PostStatus status;
  final int reminderOffsetMinutes;
  final DateTime updatedAt;
  final bool syncPending;

  CalendarPost copyWith({
    String? id,
    String? clientId,
    String? title,
    String? captionStub,
    Set<PostPlatform>? platforms,
    DateTime? scheduledAt,
    PostStatus? status,
    int? reminderOffsetMinutes,
    DateTime? updatedAt,
    bool? syncPending,
    bool clearTitle = false,
    bool clearCaptionStub = false,
  }) {
    return CalendarPost(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      title: clearTitle ? null : (title ?? this.title),
      captionStub: clearCaptionStub ? null : (captionStub ?? this.captionStub),
      platforms: platforms ?? this.platforms,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      reminderOffsetMinutes:
          reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
      syncPending: syncPending ?? this.syncPending,
    );
  }
}

enum PostPlatform {
  ig,
  tiktok,
  youtube,
  other;

  String get label {
    switch (this) {
      case PostPlatform.ig:
        return 'IG';
      case PostPlatform.tiktok:
        return 'TikTok';
      case PostPlatform.youtube:
        return 'YT';
      case PostPlatform.other:
        return 'Other';
    }
  }

  /// Wire / DB value (`ig`,`tiktok`,`yt`,`other` per Backend §2.2).
  String get storageValue {
    switch (this) {
      case PostPlatform.ig:
        return 'ig';
      case PostPlatform.tiktok:
        return 'tiktok';
      case PostPlatform.youtube:
        return 'yt';
      case PostPlatform.other:
        return 'other';
    }
  }

  static PostPlatform? fromStorage(String value) {
    switch (value) {
      case 'ig':
        return PostPlatform.ig;
      case 'tiktok':
        return PostPlatform.tiktok;
      case 'yt':
      case 'youtube':
        return PostPlatform.youtube;
      case 'other':
        return PostPlatform.other;
      default:
        return null;
    }
  }
}

enum PostStatus {
  planned,
  reminded,
  done,
  skipped;

  String get labelDe {
    switch (this) {
      case PostStatus.planned:
        return 'Geplant';
      case PostStatus.reminded:
        return 'Erinnert';
      case PostStatus.done:
        return 'Erledigt';
      case PostStatus.skipped:
        return 'Übersprungen';
    }
  }

  String get storageValue => name;

  static PostStatus fromStorage(String value) {
    return PostStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PostStatus.planned,
    );
  }
}

/// Allowed reminder offsets (US-F1-03).
abstract final class ReminderOffsets {
  static const allowed = [15, 30, 60];
  static const defaultMinutes = 30;
}
