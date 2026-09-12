# Werkly

Android-first content planning MVP (`com.werkly.app`).

This repository is the Flutter scaffold under `apps/werkly`.

## F1 — Wochen-Content-Kalender

| Screen | ID | Path |
|--------|----|------|
| WeekCalendarScreen | S-10 | `/planen` |
| PostEditorScreen | S-11 | `/planen/post`, `/planen/post/:id` |
| ReminderSettingsScreen | S-12 | `/planen/reminder-settings` |
| WeekTemplatePickerScreen | S-13 | `/planen/templates` |

- Free: **10 posts / ISO week (Europe/Berlin)** · local reminders · offline-first SQLite
- Copy: **„Reminder · manuell posten“**

## F2 — AI Caption & Hook Generator

| Screen | ID | Path |
|--------|----|------|
| CaptionHomeScreen | S-20 | `/texte` |
| CaptionResultScreen | S-21 | `/texte/result/:generationId` |
| CaptionFavoritesScreen | S-22 | `/texte/favorites` |

**Contracts**

- Edge: `POST /functions/v1/generate-caption` (see `novaforge-product/contracts/GENERATE-CAPTION-V1.md`)
- Free: **10 generations / calendar month (UTC `YYYY-MM`)** → soft paywall `limit_captions`
- Local `MockCaptionGenerator` when Supabase not configured — JSON shapes match `assets/contracts/mocks/`
- Deep-link **In Kalender** → PostEditor with `CaptionPrefill` (`go_router` extra)
- Online required for generate; policy reject on empty / `BLOCK`

## F3 — Link-Hub + Media Kit

| Screen | ID | Path |
|--------|----|------|
| HubEditorScreen | S-30 | `/hub` |
| HubLinkEditorScreen | S-31 | `/hub/link`, `/hub/link/:id` |
| MediaKitEditorScreen | S-32 | `/hub/media-kit` |
| HubPreviewScreen | S-33 | `/hub/preview` |
| HubAnalyticsScreen | S-34 | `/hub/analytics` |

**Contracts**

- Local CRUD hubs / hub_links / media_kits (memory + optional JSON persist)
- Public URL: `https://werkly.app/h/{slug}` · OpenAPI `GET public-hub?slug=` + `POST track-hub-click`
- Free: **1 hub** + **Powered by Werkly** branding; Pro: custom slug + branding off
- Soft paywall `limit_hub_branding` on branding toggle / custom slug when !pro
- Share: system sheet + copy link; preview Flutter mock of public landing

## F4 — Deal-Tracker light

| Screen | ID | Path |
|--------|----|------|
| DealListScreen | S-40 | `/deals` |
| DealEditorScreen | S-41 | `/deals/new`, `/deals/:id` |
| DealExportScreen | S-42 | `/deals/export` |

**Contracts**

- Local CRUD deals (memory + optional JSON persist) · Backend table `deals` + soft-delete
- Status enums: `inquiry|negotiation|won|invoiced|lost` (DE: Anfrage→…→Abgerechnet/Verloren)
- Open = status ≠ invoiced|lost; Free: **max 5 open** → soft paywall `limit_deals`
- Amounts: `amount_cents` + EUR
- CSV Pro: Edge `GET /functions/v1/deals-export` + local CSV fallback
- Disclaimer: Rechnung selbst / Steuerberater — **keine Buchhaltung**

## Run

```bash
cd apps/werkly
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart
# or:
flutter run -t lib/main.dart
```

## Tests

```bash
cd apps/werkly
flutter test test/features/calendar/
flutter test test/features/captions/
flutter test test/features/hub/
flutter test test/features/deals/
```

## Out of scope (this slice)

Real LLM keys, video gen, GitHub push, Play Store upload, auto-publish, real public web host, bookkeeping/invoicing.
