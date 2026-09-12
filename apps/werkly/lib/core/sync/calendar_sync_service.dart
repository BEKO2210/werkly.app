import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/calendar/data/supabase_calendar_repository.dart';
import 'package:werkly/features/calendar/domain/calendar_repository.dart';

/// Offline queue → remote upsert on `(user_id, client_id)` when online.
///
/// Reminders stay **local only** (no server push). See ReminderScheduler.
class CalendarSyncService {
  CalendarSyncService({
    required CalendarRepository local,
    SupabaseCalendarRepository? remote,
    Connectivity? connectivity,
    this.userIdProvider,
  })  : _local = local,
        _remote = remote ?? const SupabaseCalendarRepository(),
        _connectivity = connectivity ?? Connectivity();

  final CalendarRepository _local;
  final SupabaseCalendarRepository _remote;
  final Connectivity _connectivity;

  /// Returns current auth user id when available; null keeps pending.
  final Future<String?> Function()? userIdProvider;

  /// Try sync pending rows. No-ops if offline or Supabase not configured.
  Future<int> trySync() async {
    if (!WerklySupabase.isConfigured) return 0;

    final status = await _connectivity.checkConnectivity();
    final offline = status.contains(ConnectivityResult.none) ||
        status.isEmpty;
    if (offline) return 0;

    final userId = userIdProvider != null ? await userIdProvider!() : null;
    if (userId == null || userId.isEmpty) return 0;

    final pending = await _local.getPendingSync();
    var synced = 0;
    for (final post in pending) {
      final ok = await _remote.upsertOnClientId(post, userId: userId);
      if (ok) {
        await _local.markSynced(post.clientId);
        synced++;
      }
    }
    return synced;
  }
}
