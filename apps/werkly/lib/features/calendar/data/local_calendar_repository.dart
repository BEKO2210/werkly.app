import 'package:werkly/features/calendar/data/calendar_local_store.dart';
import 'package:werkly/features/calendar/domain/calendar_post.dart';
import 'package:werkly/features/calendar/domain/calendar_repository.dart';

/// Offline-first calendar repository — real local CRUD via [CalendarLocalStore].
class LocalCalendarRepository implements CalendarRepository {
  LocalCalendarRepository(this._store);

  final CalendarLocalStore _store;

  @override
  Future<List<CalendarPost>> getPostsForWeek(DateTime weekStart) {
    return _store.postsForIsoWeek(weekStart);
  }

  @override
  Future<CalendarPost?> getByClientId(String clientId) {
    return _store.byClientId(clientId);
  }

  @override
  Future<CalendarPost?> getById(String id) => _store.byId(id);

  @override
  Future<CalendarPost> save(CalendarPost post) {
    // Local upsert on client_id; remote will upsert on (user_id, client_id).
    return _store.upsert(post.copyWith(syncPending: true));
  }

  @override
  Future<void> updateStatus(String clientId, PostStatus status) {
    return _store.updateStatus(clientId, status);
  }

  @override
  Future<void> deleteByClientId(String clientId) {
    return _store.deleteByClientId(clientId);
  }

  @override
  Future<int> countPostsInWeek(DateTime weekStart) {
    return _store.countInIsoWeek(weekStart);
  }

  @override
  Future<List<CalendarPost>> getPendingSync() => _store.pendingSync();

  @override
  Future<void> markSynced(String clientId) => _store.markSynced(clientId);
}
