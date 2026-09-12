import 'package:flutter_test/flutter_test.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/calendar/domain/calendar_post.dart';
import 'package:werkly/features/calendar/domain/post_validation.dart';
import 'package:werkly/features/calendar/domain/week_utils.dart';

void main() {
  group('PostValidator (F1-T02 / AC-2)', () {
    test('requires title or captionStub, ≥1 platform, date', () {
      final bad = PostValidator.validate(
        title: '',
        captionStub: '  ',
        platforms: {},
        scheduledAt: null,
      );
      expect(bad.isValid, isFalse);
      expect(bad.errors.length, greaterThanOrEqualTo(3));

      final ok = PostValidator.validate(
        title: 'Reel Hook',
        captionStub: null,
        platforms: {PostPlatform.ig, PostPlatform.tiktok},
        scheduledAt: DateTime(2026, 9, 14, 18),
      );
      expect(ok.isValid, isTrue);

      final captionOnly = PostValidator.validate(
        title: null,
        captionStub: 'Nur Stub',
        platforms: {PostPlatform.youtube},
        scheduledAt: DateTime(2026, 9, 14),
      );
      expect(captionOnly.isValid, isTrue);
    });
  });

  group('Quota soft gate (F1-T06) — ISO week Berlin', () {
    test('blocks create at 10 for Free; Pro never blocked', () {
      expect(shouldSoftGateCalendarCreate(9), isFalse);
      expect(shouldSoftGateCalendarCreate(10), isTrue);
      expect(shouldSoftGateCalendarCreate(11), isTrue);
      expect(shouldSoftGateCalendarCreate(10, isPro: true), isFalse);
      expect(QuotaPolicy.freeWeeklyCalendarPosts, 10);
    });

    test('ISO week Monday start', () {
      // 2026-09-12 is Saturday → week start Monday 2026-09-07
      final sat = DateTime(2026, 9, 12);
      final start = WeekUtils.startOfIsoWeek(sat);
      expect(start.weekday, DateTime.monday);
      expect(start.day, 7);
      expect(WeekUtils.isInIsoWeek(sat, start), isTrue);
      expect(
        WeekUtils.isInIsoWeek(DateTime(2026, 9, 14), start),
        isTrue,
      );
      expect(
        WeekUtils.isInIsoWeek(DateTime(2026, 9, 6), start),
        isFalse,
      );
    });
  });

  group('Copy / status', () {
    test('status labels DE and storage', () {
      expect(PostStatus.planned.labelDe, 'Geplant');
      expect(PostStatus.reminded.labelDe, 'Erinnert');
      expect(PostStatus.done.labelDe, 'Erledigt');
      expect(PostStatus.skipped.labelDe, 'Übersprungen');
      expect(PostPlatform.youtube.storageValue, 'yt');
    });
  });
}
