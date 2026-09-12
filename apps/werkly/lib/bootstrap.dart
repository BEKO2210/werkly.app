import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:werkly/app.dart';
import 'package:werkly/core/config/flavor.dart';
import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/calendar/data/calendar_local_store.dart';
import 'package:werkly/features/calendar/data/calendar_sqlite_store.dart';
import 'package:werkly/features/calendar/notifications/reminder_scheduler.dart';
import 'package:werkly/features/calendar/providers/calendar_providers.dart';

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.current = flavor;

  // Stubs only — no API keys / RC keys / Sentry DSN in scaffold.
  await WerklySupabase.initStub();

  try {
    await initializeDateFormatting('de_DE');
  } catch (_) {}

  // F1: SQLite file store when native libs work; else in-memory (still usable).
  CalendarLocalStore localStore;
  try {
    final sqlite = await CalendarSqliteStore.openDefault();
    await sqlite.ensureReady();
    localStore = SqliteCalendarLocalStore(sqlite);
  } catch (_) {
    localStore = MemoryCalendarLocalStore();
    await localStore.ensureReady();
  }

  // Local reminders only (no server push). Permission failures are soft.
  final scheduler = ReminderScheduler();
  try {
    await scheduler.init();
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        calendarLocalStoreProvider.overrideWith((ref) {
          ref.onDispose(() => localStore.close());
          return localStore;
        }),
        reminderSchedulerProvider.overrideWithValue(scheduler),
        notificationPermissionGrantedProvider
            .overrideWith((ref) => scheduler.permissionGranted),
      ],
      child: const WerklyApp(),
    ),
  );
}
