import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/calendar/domain/calendar_post.dart';

/// Remote stub — upsert on `(user_id, client_id)` when Supabase is configured.
///
/// MVP: no-ops unless [WerklySupabase.isConfigured]. Real sync lives in
/// [CalendarSyncService.trySync].
class SupabaseCalendarRepository {
  const SupabaseCalendarRepository();

  /// Upsert payload for `calendar_posts` conflict target `(user_id, client_id)`.
  Map<String, dynamic> toUpsertRow(CalendarPost post, {required String userId}) {
    return {
      'user_id': userId,
      'client_id': post.clientId,
      'title': post.title,
      'caption_stub': post.captionStub,
      'platforms': post.platforms.map((p) => p.storageValue).toList(),
      'scheduled_at': post.scheduledAt.toUtc().toIso8601String(),
      'status': post.status.storageValue,
      'reminder_offset_min': post.reminderOffsetMinutes,
      'updated_at': post.updatedAt.toUtc().toIso8601String(),
    };
  }

  /// When online + Supabase wired: upsert on conflict `(user_id, client_id)`.
  /// Scaffold: returns false (keeps syncPending).
  Future<bool> upsertOnClientId(CalendarPost post, {required String userId}) async {
    if (!WerklySupabase.isConfigured) {
      // Offline / stub: leave pending. No server push for reminders.
      return false;
    }
    // TODO: supabase.from('calendar_posts').upsert(row, onConflict: 'user_id,client_id')
    final _ = toUpsertRow(post, userId: userId);
    return false;
  }
}
