/// Intended Drift DAO surface (activated after build_runner).
///
/// Runtime F1 CRUD: [CalendarSqliteStore] / [LocalCalendarRepository].
/// Remote upsert conflict target: `(user_id, client_id)`.
///
/// ```dart
/// // After codegen:
/// @DriftAccessor(tables: [CalendarPosts])
/// class CalendarPostsDao extends DatabaseAccessor<AppDatabase>
///     with _$CalendarPostsDaoMixin {
///   CalendarPostsDao(super.db);
///   Future<void> upsertByClientId(...) async { ... }
/// }
/// ```
library;
