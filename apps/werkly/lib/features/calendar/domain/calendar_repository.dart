import 'package:werkly/features/calendar/domain/calendar_post.dart';

/// Offline-first calendar repository (F1).
abstract class CalendarRepository {
  Future<List<CalendarPost>> getPostsForWeek(DateTime weekStart);

  Future<CalendarPost?> getByClientId(String clientId);

  Future<CalendarPost?> getById(String id);

  /// Upsert by [CalendarPost.clientId]; marks [CalendarPost.syncPending].
  Future<CalendarPost> save(CalendarPost post);

  Future<void> updateStatus(String clientId, PostStatus status);

  Future<void> deleteByClientId(String clientId);

  Future<int> countPostsInWeek(DateTime weekStart);

  Future<List<CalendarPost>> getPendingSync();

  Future<void> markSynced(String clientId);
}
