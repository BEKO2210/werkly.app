import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/calendar/domain/calendar_post.dart';
import 'package:werkly/features/calendar/providers/calendar_providers.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-13 — Week templates (Pro soft gate).
class WeekTemplatePickerScreen extends ConsumerWidget {
  const WeekTemplatePickerScreen({super.key});

  static const screenId = ScreenIds.weekTemplatePicker;

  static final _templates = <_Tpl>[
    _Tpl(
      name: '3× Reel, 2× Story',
      slots: [
        (title: 'Reel 1', platforms: {PostPlatform.ig}, dayOffset: 0, hour: 18),
        (title: 'Reel 2', platforms: {PostPlatform.ig, PostPlatform.tiktok}, dayOffset: 2, hour: 18),
        (title: 'Reel 3', platforms: {PostPlatform.tiktok}, dayOffset: 4, hour: 19),
        (title: 'Story A', platforms: {PostPlatform.ig}, dayOffset: 1, hour: 12),
        (title: 'Story B', platforms: {PostPlatform.ig}, dayOffset: 3, hour: 12),
      ],
    ),
    _Tpl(
      name: 'YT + Shorts Woche',
      slots: [
        (title: 'Longform', platforms: {PostPlatform.youtube}, dayOffset: 2, hour: 17),
        (title: 'Short 1', platforms: {PostPlatform.youtube, PostPlatform.tiktok}, dayOffset: 0, hour: 12),
        (title: 'Short 2', platforms: {PostPlatform.youtube}, dayOffset: 4, hour: 12),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wochen-Vorlagen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'S-13 · Reminder · manuell posten',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (!isPro)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                title: const Text('Pro-Feature'),
                subtitle: const Text(
                  'Wochen-Vorlagen sind mit Werkly Pro verfügbar.',
                ),
                trailing: FilledButton(
                  onPressed: () => context.push(
                    '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerTemplates}',
                  ),
                  child: const Text('Pro'),
                ),
              ),
            ),
          ..._templates.map((t) {
            return Card(
              child: ListTile(
                title: Text(t.name),
                subtitle: Text('${t.slots.length} Slots · aktuelle ISO-Woche'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  if (!isPro) {
                    context.push(
                      '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerTemplates}',
                    );
                    return;
                  }
                  final week =
                      ref.read(selectedWeekStartProvider);
                  await ref
                      .read(calendarNotifierProvider.notifier)
                      .applyWeekTemplate(weekStart: week, slots: t.slots);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Vorlage „${t.name}“ übernommen — Reminder · manuell posten',
                        ),
                      ),
                    );
                    context.go(RoutePaths.planen);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Tpl {
  const _Tpl({required this.name, required this.slots});
  final String name;
  final List<
      ({
        String title,
        Set<PostPlatform> platforms,
        int dayOffset,
        int hour
      })> slots;
}
