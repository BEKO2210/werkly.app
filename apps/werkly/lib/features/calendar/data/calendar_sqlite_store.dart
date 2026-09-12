import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:werkly/features/calendar/domain/calendar_post.dart';
import 'package:werkly/features/calendar/domain/week_utils.dart';

/// Real local SQLite persistence for F1 (offline-first).
/// Schema mirrors Drift `calendar_posts` / Backend §2.2.
///
/// Uses Drift [NativeDatabase] + raw SQL so CRUD works before/without
/// full `build_runner` DAO generation. Upsert key locally: [clientId].
/// Remote upsert: `(user_id, client_id)` via [SupabaseCalendarRepository].
class CalendarSqliteStore {
  CalendarSqliteStore(this._executor);

  final QueryExecutor _executor;
  bool _ready = false;

  /// In-memory DB for unit tests / scaffold without path_provider.
  factory CalendarSqliteStore.memory() {
    return CalendarSqliteStore(NativeDatabase.memory());
  }

  /// File-backed DB under app documents (Flutter).
  static Future<CalendarSqliteStore> openDefault() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'werkly_calendar.sqlite'));
    return CalendarSqliteStore(NativeDatabase(file));
  }

  Future<void> ensureReady() async {
    if (_ready) return;
    await _executor.ensureOpen(_DummyExecutorUser());
    await _executor.runCustom('''
CREATE TABLE IF NOT EXISTS calendar_posts (
  id TEXT NOT NULL PRIMARY KEY,
  client_id TEXT NOT NULL UNIQUE,
  title TEXT,
  caption_stub TEXT,
  platforms TEXT NOT NULL,
  scheduled_at INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'planned',
  reminder_offset_minutes INTEGER NOT NULL DEFAULT 30,
  updated_at INTEGER NOT NULL,
  sync_pending INTEGER NOT NULL DEFAULT 1
);
''');
    await _executor.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_cal_scheduled ON calendar_posts(scheduled_at);',
    );
    _ready = true;
  }

  Future<List<CalendarPost>> postsForIsoWeek(DateTime weekStart) async {
    await ensureReady();
    final start = WeekUtils.startOfIsoWeek(weekStart);
    final end = WeekUtils.endOfIsoWeek(start);
    final rows = await _executor.runSelect(
      '''
SELECT * FROM calendar_posts
WHERE scheduled_at >= ? AND scheduled_at < ?
ORDER BY scheduled_at ASC
''',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return rows.map(_fromRow).toList();
  }

  Future<int> countInIsoWeek(DateTime weekStart) async {
    await ensureReady();
    final start = WeekUtils.startOfIsoWeek(weekStart);
    final end = WeekUtils.endOfIsoWeek(start);
    final rows = await _executor.runSelect(
      '''
SELECT COUNT(*) AS c FROM calendar_posts
WHERE scheduled_at >= ? AND scheduled_at < ?
''',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<CalendarPost?> byClientId(String clientId) async {
    await ensureReady();
    final rows = await _executor.runSelect(
      'SELECT * FROM calendar_posts WHERE client_id = ? LIMIT 1',
      [clientId],
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<CalendarPost?> byId(String id) async {
    await ensureReady();
    final rows = await _executor.runSelect(
      'SELECT * FROM calendar_posts WHERE id = ? LIMIT 1',
      [id],
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  /// Local upsert on [client_id] (offline idempotency). Marks sync_pending=1.
  Future<CalendarPost> upsert(CalendarPost post) async {
    await ensureReady();
    final platforms = post.platforms.map((e) => e.storageValue).join(',');
    await _executor.runCustom(
      '''
INSERT INTO calendar_posts (
  id, client_id, title, caption_stub, platforms, scheduled_at,
  status, reminder_offset_minutes, updated_at, sync_pending
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
ON CONFLICT(client_id) DO UPDATE SET
  id=excluded.id,
  title=excluded.title,
  caption_stub=excluded.caption_stub,
  platforms=excluded.platforms,
  scheduled_at=excluded.scheduled_at,
  status=excluded.status,
  reminder_offset_minutes=excluded.reminder_offset_minutes,
  updated_at=excluded.updated_at,
  sync_pending=1
''',
      [
        post.id,
        post.clientId,
        post.title,
        post.captionStub,
        platforms,
        post.scheduledAt.millisecondsSinceEpoch,
        post.status.storageValue,
        post.reminderOffsetMinutes,
        post.updatedAt.millisecondsSinceEpoch,
      ],
    );
    return post.copyWith(syncPending: true);
  }

  Future<void> updateStatus(String clientId, PostStatus status) async {
    await ensureReady();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _executor.runCustom(
      '''
UPDATE calendar_posts
SET status = ?, updated_at = ?, sync_pending = 1
WHERE client_id = ?
''',
      [status.storageValue, now, clientId],
    );
  }

  Future<void> deleteByClientId(String clientId) async {
    await ensureReady();
    await _executor.runCustom(
      'DELETE FROM calendar_posts WHERE client_id = ?',
      [clientId],
    );
  }

  Future<List<CalendarPost>> pendingSync() async {
    await ensureReady();
    final rows = await _executor.runSelect(
      'SELECT * FROM calendar_posts WHERE sync_pending = 1 ORDER BY updated_at ASC',
      const [],
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> markSynced(String clientId) async {
    await ensureReady();
    await _executor.runCustom(
      'UPDATE calendar_posts SET sync_pending = 0 WHERE client_id = ?',
      [clientId],
    );
  }

  Future<void> close() => _executor.close();

  CalendarPost _fromRow(Map<String, Object?> row) {
    final platformStr = row['platforms'] as String? ?? '';
    final platforms = platformStr
        .split(',')
        .where((s) => s.isNotEmpty)
        .map(PostPlatform.fromStorage)
        .whereType<PostPlatform>()
        .toSet();
    return CalendarPost(
      id: row['id'] as String,
      clientId: row['client_id'] as String,
      title: row['title'] as String?,
      captionStub: row['caption_stub'] as String?,
      platforms: platforms,
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(
        row['scheduled_at'] as int,
      ),
      status: PostStatus.fromStorage(row['status'] as String? ?? 'planned'),
      reminderOffsetMinutes: (row['reminder_offset_minutes'] as int?) ?? 30,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int,
      ),
      syncPending: ((row['sync_pending'] as int?) ?? 1) == 1,
    );
  }
}

/// Minimal [QueryExecutorUser] so [QueryExecutor.ensureOpen] works.
class _DummyExecutorUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
