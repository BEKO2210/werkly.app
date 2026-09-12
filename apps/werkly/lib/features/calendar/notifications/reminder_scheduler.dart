import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:werkly/features/calendar/domain/calendar_post.dart';

/// Local-only reminder scheduling (F1 AC-3). **No server push.**
///
/// Copy: „Reminder · manuell posten“ — never auto-publish.
class ReminderScheduler {
  ReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool permissionGranted = false;

  static const _channelId = 'werkly_reminders';
  static const _channelName = 'Post-Reminders';
  static const manualPostCopy = 'Reminder · manuell posten';

  Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      // Stub: Europe/Berlin; flutter_timezone can refine at runtime.
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    } catch (_) {
      // Tests / missing tz DB — keep going.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
    await refreshPermission();
  }

  Future<bool> refreshPermission() async {
    try {
      final status = await Permission.notification.status;
      permissionGranted = status.isGranted;
    } catch (_) {
      permissionGranted = false;
    }
    return permissionGranted;
  }

  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      permissionGranted = status.isGranted;
    } catch (_) {
      permissionGranted = false;
    }
    return permissionGranted;
  }

  /// Schedule local reminder at scheduledAt − offset. No-ops if no permission
  /// (caller shows banner). Never crashes on missing permission.
  Future<void> scheduleFor(CalendarPost post) async {
    await init();
    if (!permissionGranted) return;

    final when = post.scheduledAt
        .subtract(Duration(minutes: post.reminderOffsetMinutes));
    if (when.isBefore(DateTime.now())) return;

    final title = post.title?.trim().isNotEmpty == true
        ? post.title!
        : (post.captionStub ?? 'Geplanter Post');
    final body =
        '$manualPostCopy · ${post.platforms.map((p) => p.label).join(", ")}';

    try {
      final tzWhen = tz.TZDateTime.from(when, tz.local);
      await _plugin.zonedSchedule(
        _notifId(post.clientId),
        title,
        body,
        tzWhen,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: manualPostCopy,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: post.clientId,
      );
    } catch (_) {
      // Never crash calendar flow on notification failures.
    }
  }

  Future<void> cancelFor(String clientId) async {
    await init();
    try {
      await _plugin.cancel(_notifId(clientId));
    } catch (_) {}
  }

  /// Stable 31-bit id from clientId hash.
  int _notifId(String clientId) => clientId.hashCode & 0x7fffffff;
}
