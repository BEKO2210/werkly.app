# apps/werkly

Flutter application package **Werkly** · applicationId `com.werkly.app`.

Screen-IDs/routes match MOBILE-ARCH-CODEPLAN-MVP-V1.md **§4** (S-00 `/auth`, S-10 `/planen`, S-60 `/paywall`).

## F1 local data

1. `flutter pub get`
2. Optional Drift codegen: `dart run build_runner build --delete-conflicting-outputs`
3. Runtime persistence: SQLite via `CalendarSqliteStore` (file under app documents)

See repository root README.
