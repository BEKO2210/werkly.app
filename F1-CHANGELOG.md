# F1 Wochen-Content-Kalender — Changelog

**App:** Werkly (`com.werkly.app`)  
**Scope:** US-F1-01..05 (05 Pro Should) · usable local CRUD, not stubs

## Contracts

1. Upsert remote: `(user_id, client_id)` — see `SupabaseCalendarRepository` / `CalendarSyncService.trySync`
2. Free quota: **10 posts / ISO week Europe/Berlin** (`WeekUtils` + `QuotaPolicy`)
3. Reminders: **local only** (`ReminderScheduler`) — no server push
4. Offline-first SQLite + `syncPending` queue
5. Copy: „Reminder · manuell posten“ / never auto-publish

## Files touched / added

### Domain
- `apps/werkly/lib/features/calendar/domain/calendar_post.dart`
- `apps/werkly/lib/features/calendar/domain/calendar_repository.dart`
- `apps/werkly/lib/features/calendar/domain/post_validation.dart`
- `apps/werkly/lib/features/calendar/domain/week_utils.dart`

### Data / Drift / Sync
- `apps/werkly/lib/features/calendar/data/calendar_sqlite_store.dart` — **real SQLite CRUD** (Drift NativeDatabase)
- `apps/werkly/lib/features/calendar/data/calendar_memory_store.dart` — in-memory fallback (same semantics)
- `apps/werkly/lib/features/calendar/data/calendar_local_store.dart` — unified store interface
- `apps/werkly/lib/features/calendar/data/local_calendar_repository.dart`
- `apps/werkly/lib/features/calendar/data/supabase_calendar_repository.dart`
- `apps/werkly/lib/features/calendar/data/drift/calendar_posts_table.dart`
- `apps/werkly/lib/features/calendar/data/drift/app_database.dart`
- `apps/werkly/lib/features/calendar/data/drift/calendar_posts_dao.dart`
- `apps/werkly/lib/core/sync/calendar_sync_service.dart`
- `apps/werkly/lib/core/network/supabase_client.dart` (`isConfigured`)
- `apps/werkly/lib/core/entitlements/quota_policy.dart`
- `apps/werkly/lib/core/entitlements/entitlements.dart`

### Notifications / Providers
- `apps/werkly/lib/features/calendar/notifications/reminder_scheduler.dart`
- `apps/werkly/lib/features/calendar/providers/calendar_providers.dart`
- `apps/werkly/lib/bootstrap.dart`

### Presentation (S-10..S-13, S-06, S-60, widgets)
- `week_calendar_screen.dart`, `post_editor_screen.dart`
- `reminder_settings_screen.dart`, `week_template_picker_screen.dart`
- `widgets/*` (week_strip, post_card, status_pill, platform_chips, notification_permission_banner)
- `features/permissions/notification_permission_screen.dart`
- `features/paywall/paywall_screen.dart` (trigger query)
- `ui/widgets/quota_banner.dart`

### Config / docs / tests
- `apps/werkly/pubspec.yaml` (drift, sqlite3_flutter_libs, path_provider, build_runner, …)
- `README.md` (Werkly), `apps/werkly/README.md`
- `test/features/calendar/post_validation_quota_test.dart`
- `test/features/calendar/local_calendar_crud_test.dart`
- `FILELIST.txt`, this changelog

## How to verify US-F1-01..04

| Story | Verify |
|-------|--------|
| **US-F1-01** | Open S-10 `/planen`: Mo–So strip, prev/next week, FAB → S-11, create post with title/caption, platforms, datetime; card shows on week list |
| **US-F1-02** | In S-11 select multiple platform chips (IG/TikTok/YT/Other); saved card shows chips |
| **US-F1-03** | S-12 / S-06: grant or deny notifications; denied → banner on S-10 → permission screen / system settings; reminder copy says manuell posten; offsets 15/30/60 |
| **US-F1-04** | Edit post → status chips Geplant/Erinnert/Erledigt/Übersprungen persist after reopen |
| Soft gate | Create 10 posts in current ISO week as Free → 11th → `/paywall?trigger=limit_calendar_posts`; list still readable |
| Offline | Airplane mode: save post locally (`syncPending`); online + Supabase configured later → `trySync` upserts on `(user_id, client_id)` |

```bash
cd apps/werkly && flutter pub get && flutter test test/features/calendar/
dart run build_runner build --delete-conflicting-outputs   # optional Drift DAO
```
