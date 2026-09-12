import 'package:drift/drift.dart';
import 'package:werkly/features/calendar/data/drift/calendar_posts_table.dart';

// After codegen, uncomment and use:
// part 'app_database.g.dart';
//
// @DriftDatabase(tables: [CalendarPosts])
// class AppDatabase extends _$AppDatabase {
//   AppDatabase(super.e);
//   @override
//   int get schemaVersion => 1;
// }
//
// Run: dart run build_runner build --delete-conflicting-outputs
//
// Until then, F1 local CRUD uses [CalendarSqliteStore] with the same
// `calendar_posts` schema (see calendar_sqlite_store.dart).

/// Schema version constant shared with [CalendarSqliteStore].
const kCalendarSchemaVersion = 1;

/// Re-export table for discoverability.
typedef CalendarPostsTable = CalendarPosts;
