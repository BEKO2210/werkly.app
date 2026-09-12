import 'package:werkly/features/calendar/data/calendar_memory_store.dart';
import 'package:werkly/features/calendar/data/calendar_sqlite_store.dart';
import 'package:werkly/features/calendar/domain/calendar_post.dart';

/// Unified local persistence for F1 (SQLite preferred, memory fallback).
abstract class CalendarLocalStore {
  Future<void> ensureReady();
  Future<List<CalendarPost>> postsForIsoWeek(DateTime weekStart);
  Future<int> countInIsoWeek(DateTime weekStart);
  Future<CalendarPost?> byClientId(String clientId);
  Future<CalendarPost?> byId(String id);
  Future<CalendarPost> upsert(CalendarPost post);
  Future<void> updateStatus(String clientId, PostStatus status);
  Future<void> deleteByClientId(String clientId);
  Future<List<CalendarPost>> pendingSync();
  Future<void> markSynced(String clientId);
  Future<void> close();
}

class SqliteCalendarLocalStore implements CalendarLocalStore {
  SqliteCalendarLocalStore(this._inner);
  final CalendarSqliteStore _inner;

  @override
  Future<void> ensureReady() => _inner.ensureReady();
  @override
  Future<List<CalendarPost>> postsForIsoWeek(DateTime w) =>
      _inner.postsForIsoWeek(w);
  @override
  Future<int> countInIsoWeek(DateTime w) => _inner.countInIsoWeek(w);
  @override
  Future<CalendarPost?> byClientId(String id) => _inner.byClientId(id);
  @override
  Future<CalendarPost?> byId(String id) => _inner.byId(id);
  @override
  Future<CalendarPost> upsert(CalendarPost p) => _inner.upsert(p);
  @override
  Future<void> updateStatus(String id, PostStatus s) =>
      _inner.updateStatus(id, s);
  @override
  Future<void> deleteByClientId(String id) => _inner.deleteByClientId(id);
  @override
  Future<List<CalendarPost>> pendingSync() => _inner.pendingSync();
  @override
  Future<void> markSynced(String id) => _inner.markSynced(id);
  @override
  Future<void> close() => _inner.close();
}

class MemoryCalendarLocalStore implements CalendarLocalStore {
  MemoryCalendarLocalStore([CalendarMemoryStore? inner])
      : _inner = inner ?? CalendarMemoryStore();
  final CalendarMemoryStore _inner;

  @override
  Future<void> ensureReady() async {}
  @override
  Future<List<CalendarPost>> postsForIsoWeek(DateTime w) =>
      _inner.postsForIsoWeek(w);
  @override
  Future<int> countInIsoWeek(DateTime w) => _inner.countInIsoWeek(w);
  @override
  Future<CalendarPost?> byClientId(String id) => _inner.byClientId(id);
  @override
  Future<CalendarPost?> byId(String id) => _inner.byId(id);
  @override
  Future<CalendarPost> upsert(CalendarPost p) => _inner.upsert(p);
  @override
  Future<void> updateStatus(String id, PostStatus s) =>
      _inner.updateStatus(id, s);
  @override
  Future<void> deleteByClientId(String id) => _inner.deleteByClientId(id);
  @override
  Future<List<CalendarPost>> pendingSync() => _inner.pendingSync();
  @override
  Future<void> markSynced(String id) => _inner.markSynced(id);
  @override
  Future<void> close() async {}
}
