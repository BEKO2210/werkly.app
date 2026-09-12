import 'package:werkly/features/calendar/domain/calendar_post.dart';
import 'package:werkly/features/calendar/domain/week_utils.dart';

/// Pure Dart in-memory store — same semantics as [CalendarSqliteStore].
/// Used when SQLite native libs are unavailable (tests / degraded devices).
class CalendarMemoryStore {
  final Map<String, CalendarPost> _byClientId = {};

  Future<List<CalendarPost>> postsForIsoWeek(DateTime weekStart) async {
    final start = WeekUtils.startOfIsoWeek(weekStart);
    final end = WeekUtils.endOfIsoWeek(start);
    final list = _byClientId.values
        .where((p) =>
            !p.scheduledAt.isBefore(start) && p.scheduledAt.isBefore(end))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  Future<int> countInIsoWeek(DateTime weekStart) async {
    return (await postsForIsoWeek(weekStart)).length;
  }

  Future<CalendarPost?> byClientId(String clientId) async =>
      _byClientId[clientId];

  Future<CalendarPost?> byId(String id) async {
    for (final p in _byClientId.values) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<CalendarPost> upsert(CalendarPost post) async {
    final saved = post.copyWith(syncPending: true);
    _byClientId[post.clientId] = saved;
    return saved;
  }

  Future<void> updateStatus(String clientId, PostStatus status) async {
    final existing = _byClientId[clientId];
    if (existing == null) return;
    _byClientId[clientId] = existing.copyWith(
      status: status,
      updatedAt: DateTime.now(),
      syncPending: true,
    );
  }

  Future<void> deleteByClientId(String clientId) async {
    _byClientId.remove(clientId);
  }

  Future<List<CalendarPost>> pendingSync() async {
    return _byClientId.values.where((p) => p.syncPending).toList();
  }

  Future<void> markSynced(String clientId) async {
    final existing = _byClientId[clientId];
    if (existing == null) return;
    _byClientId[clientId] = existing.copyWith(syncPending: false);
  }
}
