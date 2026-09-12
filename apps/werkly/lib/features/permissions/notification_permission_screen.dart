import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:werkly/features/calendar/providers/calendar_providers.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-06 — Request local notification permission (F1 reminders).
class NotificationPermissionScreen extends ConsumerWidget {
  const NotificationPermissionScreen({super.key});

  static const screenId = ScreenIds.notificationPermission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final granted = ref.watch(notificationPermissionGrantedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benachrichtigungen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'S-06 · Reminder · manuell posten',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Werkly erinnert dich lokal vor deinen geplanten Posts. '
              'Es wird nichts automatisch in Instagram, TikTok oder YouTube gepostet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Icon(
              granted ? Icons.notifications_active : Icons.notifications_none,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              granted
                  ? 'Berechtigung erteilt — Reminders sind aktiv.'
                  : 'Berechtigung fehlt — Reminders feuern nicht.',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (!granted) ...[
              FilledButton(
                onPressed: () async {
                  final ok = await ref
                      .read(reminderSchedulerProvider)
                      .requestPermission();
                  ref
                      .read(notificationPermissionGrantedProvider.notifier)
                      .state = ok;
                  if (!ok && context.mounted) {
                    await openAppSettings();
                  }
                },
                child: const Text('Benachrichtigungen erlauben'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => openAppSettings(),
                child: const Text('System-Einstellungen öffnen'),
              ),
            ],
            TextButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RoutePaths.planen);
                }
              },
              child: Text(granted ? 'Zurück zum Kalender' : 'Später'),
            ),
          ],
        ),
      ),
    );
  }
}
