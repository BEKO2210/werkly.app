import 'package:flutter_test/flutter_test.dart';
import 'package:werkly/features/calendar/data/calendar_local_store.dart';
import 'package:werkly/features/calendar/data/local_calendar_repository.dart';
import 'package:werkly/features/calendar/domain/calendar_post.dart';
import 'package:werkly/features/calendar/domain/week_utils.dart';

void main() {
  group('LocalCalendarRepository CRUD (offline, client_id upsert)', () {
    late LocalCalendarRepository repo;

    setUp(() {
      repo = LocalCalendarRepository(MemoryCalendarLocalStore());
    });

    test('save + list ISO week + status + syncPending + no dup client_id',
        () async {
      final week = WeekUtils.startOfIsoWeek(DateTime(2026, 9, 12));
      final post = CalendarPost(
        id: 'id-1',
        clientId: 'client-1',
        title: 'Test Reel',
        platforms: {PostPlatform.ig},
        scheduledAt: week.add(const Duration(days: 1, hours: 18)),
        status: PostStatus.planned,
        reminderOffsetMinutes: 30,
        updatedAt: DateTime(2026, 9, 12),
        syncPending: true,
      );

      final saved = await repo.save(post);
      expect(saved.syncPending, isTrue);

      final list = await repo.getPostsForWeek(week);
      expect(list, hasLength(1));
      expect(list.first.clientId, 'client-1');
      expect(await repo.countPostsInWeek(week), 1);

      await repo.updateStatus('client-1', PostStatus.done);
      final updated = await repo.getByClientId('client-1');
      expect(updated!.status, PostStatus.done);
      expect(updated.syncPending, isTrue);

      await repo.save(saved.copyWith(
        title: 'Updated',
        updatedAt: DateTime(2026, 9, 12, 1),
      ));
      expect(await repo.countPostsInWeek(week), 1);
      expect((await repo.getByClientId('client-1'))!.title, 'Updated');

      final pending = await repo.getPendingSync();
      expect(pending, isNotEmpty);
      await repo.markSynced('client-1');
      expect(await repo.getPendingSync(), isEmpty);
    });
  });
}
