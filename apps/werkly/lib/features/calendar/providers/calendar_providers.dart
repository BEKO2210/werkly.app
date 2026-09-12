import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/core/sync/calendar_sync_service.dart';
import 'package:werkly/features/calendar/data/calendar_local_store.dart';
import 'package:werkly/features/calendar/data/local_calendar_repository.dart';
import 'package:werkly/features/calendar/domain/calendar_post.dart';
import 'package:werkly/features/calendar/domain/calendar_repository.dart';
import 'package:werkly/features/calendar/domain/post_validation.dart';
import 'package:werkly/features/calendar/domain/week_utils.dart';
import 'package:werkly/features/calendar/notifications/reminder_scheduler.dart';

/// Override in [bootstrap] with file-backed SQLite when available.
final calendarLocalStoreProvider = Provider<CalendarLocalStore>((ref) {
  final store = MemoryCalendarLocalStore();
  ref.onDispose(() => store.close());
  return store;
});

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return LocalCalendarRepository(ref.watch(calendarLocalStoreProvider));
});

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return ReminderScheduler();
});

final calendarSyncServiceProvider = Provider<CalendarSyncService>((ref) {
  return CalendarSyncService(local: ref.watch(calendarRepositoryProvider));
});

final notificationPermissionGrantedProvider =
    StateProvider<bool>((ref) => false);

/// Selected ISO week start (Monday), Berlin wall-time semantics.
final selectedWeekStartProvider = StateProvider<DateTime>((ref) {
  return WeekUtils.currentWeekStartBerlin();
});

final weekPostsProvider =
    FutureProvider.family<List<CalendarPost>, DateTime>((ref, weekStart) async {
  final repo = ref.watch(calendarRepositoryProvider);
  return repo.getPostsForWeek(weekStart);
});

final weekPostCountProvider =
    FutureProvider.family<int, DateTime>((ref, weekStart) async {
  final repo = ref.watch(calendarRepositoryProvider);
  return repo.countPostsInWeek(weekStart);
});

class SavePostResult {
  const SavePostResult._({
    this.post,
    this.validation,
    this.softGated = false,
  });

  final CalendarPost? post;
  final PostValidationResult? validation;
  final bool softGated;

  bool get success => post != null && !softGated;

  factory SavePostResult.ok(CalendarPost post) => SavePostResult._(post: post);

  factory SavePostResult.invalid(PostValidationResult v) =>
      SavePostResult._(validation: v);

  factory SavePostResult.paywall() =>
      const SavePostResult._(softGated: true);
}

class CalendarNotifier extends StateNotifier<AsyncValue<void>> {
  CalendarNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;
  static const _uuid = Uuid();

  CalendarRepository get _repo => _ref.read(calendarRepositoryProvider);
  ReminderScheduler get _reminders => _ref.read(reminderSchedulerProvider);

  void invalidateWeek(DateTime weekStart) {
    _ref.invalidate(weekPostsProvider(weekStart));
    _ref.invalidate(weekPostCountProvider(weekStart));
  }

  /// Create or update. Soft-gates **new** posts when Free ISO-week count ≥ 10.
  Future<SavePostResult> savePost({
    String? existingClientId,
    String? title,
    String? captionStub,
    required Set<PostPlatform> platforms,
    required DateTime scheduledAt,
    int reminderOffsetMinutes = ReminderOffsets.defaultMinutes,
    PostStatus status = PostStatus.planned,
  }) async {
    final validation = PostValidator.validate(
      title: title,
      captionStub: captionStub,
      platforms: platforms,
      scheduledAt: scheduledAt,
    );
    if (!validation.isValid) {
      return SavePostResult.invalid(validation);
    }

    final weekStart = WeekUtils.startOfIsoWeek(scheduledAt);
    final isPro = _ref.read(isProProvider);
    final isNew = existingClientId == null;

    if (isNew) {
      final count = await _repo.countPostsInWeek(weekStart);
      if (QuotaPolicy.shouldBlockCalendarCreate(
        isPro: isPro,
        currentWeekCount: count,
      )) {
        return SavePostResult.paywall();
      }
    }

    CalendarPost? existing;
    if (existingClientId != null) {
      existing = await _repo.getByClientId(existingClientId);
    }

    final now = DateTime.now();
    final post = CalendarPost(
      id: existing?.id ?? _uuid.v4(),
      clientId: existing?.clientId ?? _uuid.v4(),
      title: title?.trim().isEmpty == true ? null : title?.trim(),
      captionStub:
          captionStub?.trim().isEmpty == true ? null : captionStub?.trim(),
      platforms: platforms,
      scheduledAt: scheduledAt,
      status: status,
      reminderOffsetMinutes: reminderOffsetMinutes,
      updatedAt: now,
      syncPending: true,
    );

    final saved = await _repo.save(post);
    await _reminders.scheduleFor(saved);
    invalidateWeek(weekStart);
    // ignore: unawaited_futures
    _ref.read(calendarSyncServiceProvider).trySync();
    return SavePostResult.ok(saved);
  }

  Future<void> setStatus(String clientId, PostStatus status) async {
    final post = await _repo.getByClientId(clientId);
    await _repo.updateStatus(clientId, status);
    if (post != null) {
      invalidateWeek(WeekUtils.startOfIsoWeek(post.scheduledAt));
      if (status == PostStatus.done || status == PostStatus.skipped) {
        await _reminders.cancelFor(clientId);
      }
    }
    // ignore: unawaited_futures
    _ref.read(calendarSyncServiceProvider).trySync();
  }

  Future<void> applyWeekTemplate({
    required DateTime weekStart,
    required List<
            ({
              String title,
              Set<PostPlatform> platforms,
              int dayOffset,
              int hour
            })>
        slots,
  }) async {
    final isPro = _ref.read(isProProvider);
    if (!QuotaPolicy.canUseWeekTemplates(isPro: isPro)) {
      return;
    }
    final start = WeekUtils.startOfIsoWeek(weekStart);
    for (final slot in slots) {
      final when = start.add(Duration(days: slot.dayOffset, hours: slot.hour));
      await savePost(
        title: slot.title,
        platforms: slot.platforms,
        scheduledAt: when,
      );
    }
  }
}

final calendarNotifierProvider =
    StateNotifierProvider<CalendarNotifier, AsyncValue<void>>((ref) {
  return CalendarNotifier(ref);
});
