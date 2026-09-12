import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/calendar/domain/week_utils.dart';
import 'package:werkly/features/calendar/providers/calendar_providers.dart';
import 'package:werkly/features/calendar/widgets/notification_permission_banner.dart';
import 'package:werkly/features/calendar/widgets/post_card.dart';
import 'package:werkly/features/calendar/widgets/week_strip.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';
import 'package:werkly/ui/widgets/quota_banner.dart';

/// Screen-ID: S-10 — Week calendar (Mo–So), ISO week Europe/Berlin.
class WeekCalendarScreen extends ConsumerStatefulWidget {
  const WeekCalendarScreen({super.key});

  static const screenId = ScreenIds.weekCalendar;

  @override
  ConsumerState<WeekCalendarScreen> createState() => _WeekCalendarScreenState();
}

class _WeekCalendarScreenState extends ConsumerState<WeekCalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scheduler = ref.read(reminderSchedulerProvider);
      await scheduler.init();
      final granted = await scheduler.refreshPermission();
      if (mounted) {
        ref.read(notificationPermissionGrantedProvider.notifier).state =
            granted;
      }
      // ignore: unawaited_futures
      ref.read(calendarSyncServiceProvider).trySync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = ref.watch(selectedWeekStartProvider);
    final postsAsync = ref.watch(weekPostsProvider(weekStart));
    final countAsync = ref.watch(weekPostCountProvider(weekStart));
    final isPro = ref.watch(isProProvider);
    final notifOk = ref.watch(notificationPermissionGrantedProvider);
    final count = countAsync.valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planen'),
        actions: [
          IconButton(
            tooltip: 'Wochen-Vorlagen',
            onPressed: () => context.push(RoutePaths.planenTemplates),
            icon: const Icon(Icons.auto_awesome_mosaic_outlined),
          ),
          IconButton(
            tooltip: 'Reminder-Einstellungen',
            onPressed: () => context.push(RoutePaths.planenReminderSettings),
            icon: const Icon(Icons.notifications_active_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!isPro &&
              QuotaPolicy.shouldBlockCalendarCreate(
                isPro: isPro,
                currentWeekCount: count,
              )) {
            context.push(
              '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerCalendar}',
            );
            return;
          }
          context.push(RoutePaths.planenPost);
        },
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
      body: Column(
        children: [
          QuotaBanner(
            used: count,
            limit: QuotaPolicy.freeWeeklyCalendarPosts,
            label: 'Posts diese ISO-Woche (Berlin)',
            trigger: QuotaPolicy.paywallTriggerCalendar,
          ),
          NotificationPermissionBanner(visible: !notifOk),
          WeekStrip(
            weekStart: weekStart,
            onPrev: () {
              ref.read(selectedWeekStartProvider.notifier).state =
                  weekStart.subtract(const Duration(days: 7));
            },
            onNext: () {
              ref.read(selectedWeekStartProvider.notifier).state =
                  weekStart.add(const Duration(days: 7));
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reminder · manuell posten',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: postsAsync.when(
              loading: () => ListView.builder(
                itemCount: 3,
                itemBuilder: (_, __) => const Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: SizedBox(height: 72),
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Fehler: $e'),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(weekPostsProvider(weekStart)),
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Noch keine Posts in dieser Woche.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () =>
                                context.push(RoutePaths.planenPost),
                            child: const Text('Ersten Post planen'),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.push(RoutePaths.planenTemplates),
                            child: const Text('Vorlage nutzen'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                // Group by weekday for Tagesliste
                final start = WeekUtils.startOfIsoWeek(weekStart);
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: 7,
                  itemBuilder: (context, dayIndex) {
                    final day = start.add(Duration(days: dayIndex));
                    final dayPosts = posts
                        .where((p) =>
                            p.scheduledAt.year == day.year &&
                            p.scheduledAt.month == day.month &&
                            p.scheduledAt.day == day.day)
                        .toList();
                    if (dayPosts.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            _weekdayLabel(dayIndex),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        ...dayPosts.map(
                          (p) => PostCard(
                            post: p,
                            onTap: () => context.push(
                              RoutePaths.planenPostId(p.clientId),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(int index) {
    const names = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];
    return names[index];
  }
}
