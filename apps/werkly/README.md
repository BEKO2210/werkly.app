# apps/werkly

Flutter application package **Werkly** · applicationId `com.werkly.app`.

Screen-IDs/routes match MOBILE-ARCH-CODEPLAN-MVP-V1.md **§4** (S-00 `/auth`, S-10 `/planen`, S-20 `/texte`, S-60 `/paywall`).

## F1 local data

1. `flutter pub get`
2. Optional Drift codegen: `dart run build_runner build --delete-conflicting-outputs`
3. Runtime persistence: SQLite via `CalendarSqliteStore` (file under app documents)

## F2 captions

- Mock / Edge client aligned with `contracts/GENERATE-CAPTION-V1.md`
- Fixture JSON under `assets/contracts/mocks/`
- Soft paywall trigger: `limit_captions` (10 Free / calendar month UTC)

```bash
flutter test test/features/captions/
```

See repository root README + `F2-CHANGELOG.md`.
