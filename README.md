# Werkly

Android-first content planning MVP (`com.werkly.app`).

This repository is the Flutter scaffold under `apps/werkly`. Feature **F1 — Wochen-Content-Kalender** is implemented as a **usable** offline-first slice (real local CRUD, soft paywall, local reminders).

## F1 — Wochen-Content-Kalender

| Screen | ID | Path |
|--------|----|------|
| WeekCalendarScreen | S-10 | `/planen` |
| PostEditorScreen | S-11 | `/planen/post`, `/planen/post/:id` |
| ReminderSettingsScreen | S-12 | `/planen/reminder-settings` |
| WeekTemplatePickerScreen | S-13 | `/planen/templates` |

**Contracts baked in**

- Local upsert by `client_id`; remote upsert on `(user_id, client_id)` when Supabase is configured
- Free quota = **10 posts per ISO week (Europe/Berlin)** — not rolling 7 days
- Reminders are **local only** (flutter_local_notifications) — no server push
- Offline-readable + sync queue (`syncPending`) when online
- Copy: **„Reminder · manuell posten“** — never auto-publish

## Run

```bash
cd apps/werkly
flutter pub get
# Drift table sources are present; full typed DAO codegen (optional upgrade path):
dart run build_runner build --delete-conflicting-outputs
flutter run --flavor dev -t lib/main_dev.dart
# or:
flutter run -t lib/main.dart
```

**Note:** Runtime F1 CRUD uses `CalendarSqliteStore` (Drift `NativeDatabase` + schema aligned with `calendar_posts`). After `build_runner`, you can migrate to generated `AppDatabase` / DAO — see `lib/features/calendar/data/drift/`.

## Tests

```bash
cd apps/werkly
flutter test test/features/calendar/
```

## Out of scope (this slice)

Real Supabase keys, F2–F5 business logic, Play Store upload, auto-publish to networks.
