import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:werkly/features/calendar/domain/calendar_post.dart';
import 'package:werkly/features/calendar/providers/calendar_providers.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-12 — Reminder settings (local only, no server push).
class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  static const screenId = ScreenIds.reminderSettings;

  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState
    extends ConsumerState<ReminderSettingsScreen> {
  int _defaultOffset = ReminderOffsets.defaultMinutes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final s = ref.read(reminderSchedulerProvider);
      await s.init();
      final ok = await s.refreshPermission();
      if (mounted) {
        ref.read(notificationPermissionGrantedProvider.notifier).state = ok;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final granted = ref.watch(notificationPermissionGrantedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminder-Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'S-12 · Reminder · manuell posten',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text(
            'Erinnerungen sind lokal auf dem Gerät. Werkly postet nicht '
            'automatisch in Netzwerke.',
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              granted ? Icons.notifications_active : Icons.notifications_off,
            ),
            title: Text(
              granted
                  ? 'Benachrichtigungen erlaubt'
                  : 'Benachrichtigungen aus',
            ),
            subtitle: Text(
              granted
                  ? 'Reminders feuern 15/30/60 Min vor der geplanten Zeit.'
                  : 'Ohne Erlaubnis gibt es nur den In-App-Hinweis.',
            ),
            trailing: granted
                ? null
                : TextButton(
                    onPressed: () async {
                      final ok = await ref
                          .read(reminderSchedulerProvider)
                          .requestPermission();
                      ref
                          .read(notificationPermissionGrantedProvider.notifier)
                          .state = ok;
                      if (!ok && mounted) {
                        context.push(RoutePaths.permissionsNotifications);
                      }
                    },
                    child: const Text('Erlauben'),
                  ),
          ),
          if (!granted)
            OutlinedButton(
              onPressed: () => openAppSettings(),
              child: const Text('Zu System-Einstellungen'),
            ),
          const Divider(height: 32),
          Text('Standard-Offset',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ReminderOffsets.allowed.map((m) {
              return ChoiceChip(
                label: Text('$m Min vorher'),
                selected: _defaultOffset == m,
                onSelected: (_) => setState(() => _defaultOffset = m),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hinweis: Reminder ≠ Publish. Du postest manuell.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
