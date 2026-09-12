import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:werkly/app.dart';
import 'package:werkly/core/auth/session_providers.dart';
import 'package:werkly/core/config/flavor.dart';
import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/calendar/data/calendar_local_store.dart';
import 'package:werkly/features/calendar/data/calendar_sqlite_store.dart';
import 'package:werkly/features/calendar/notifications/reminder_scheduler.dart';
import 'package:werkly/features/calendar/providers/calendar_providers.dart';

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.current = flavor;

  // Live when SUPABASE_URL + SUPABASE_ANON_KEY via dart-define; else stub.
  await WerklySupabase.initFromEnv();

  try {
    await initializeDateFormatting('de_DE');
  } catch (_) {}

  CalendarLocalStore localStore;
  try {
    final sqlite = await CalendarSqliteStore.openDefault();
    await sqlite.ensureReady();
    localStore = SqliteCalendarLocalStore(sqlite);
  } catch (_) {
    localStore = MemoryCalendarLocalStore();
    await localStore.ensureReady();
  }

  final scheduler = ReminderScheduler();
  try {
    await scheduler.init();
  } catch (_) {}

  final container = ProviderContainer(
    overrides: [
      calendarLocalStoreProvider.overrideWith((ref) {
        ref.onDispose(() => localStore.close());
        return localStore;
      }),
      reminderSchedulerProvider.overrideWithValue(scheduler),
      notificationPermissionGrantedProvider
          .overrideWith((ref) => scheduler.permissionGranted),
    ],
  );

  // Restore live session (no-op when mockAuth).
  await container.read(authServiceProvider).restore();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const WerklyApp(),
    ),
  );
}
