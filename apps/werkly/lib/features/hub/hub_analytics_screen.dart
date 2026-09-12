import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:werkly/features/hub/providers/hub_providers.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-34 — Stub click counts 7/30 days (local fake or zero).
class HubAnalyticsScreen extends ConsumerWidget {
  const HubAnalyticsScreen({super.key});

  static const screenId = ScreenIds.hubAnalytics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(hubAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub Analytics'),
      ),
      body: asyncStats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (stats) {
          if (stats.isEmpty) {
            return const Center(
              child: Text(
                'Noch keine Links — Analytics erscheinen nach dem ersten Link.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Klicks je Link (lokal / Demo)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '7 Tage · 30 Tage — Should MVP, kein Dashboard-Ballast',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ...stats.map(
                (s) => Card(
                  child: ListTile(
                    title: Text(s.label),
                    subtitle: Text('Link ${s.linkId.substring(0, 8)}…'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '7d: ${s.clicks7d}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('30d: ${s.clicks30d}'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'S-34 · hub_link_stats stub',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
