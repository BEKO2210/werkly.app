import 'package:drift/drift.dart';

/// Drift table matching Backend §2.2 `calendar_posts` (local columns).
///
/// After `dart run build_runner build`, wire [CalendarPostsDao] from
/// generated code. Until then [LocalCalendarRepository] uses the same
/// schema via [CalendarSqliteStore].
class CalendarPosts extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text()();
  TextColumn get title => text().nullable()();
  TextColumn get captionStub => text().nullable()();
  /// Comma-separated storage values: ig,tiktok,yt,other
  TextColumn get platforms => text()();
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('planned'))();
  IntColumn get reminderOffsetMinutes =>
      integer().withDefault(const Constant(30))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncPending =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {clientId},
      ];
}
