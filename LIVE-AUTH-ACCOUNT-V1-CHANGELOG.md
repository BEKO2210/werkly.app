# LIVE-AUTH-ACCOUNT-V1 — Changelog

**Date:** 2026-09-12 (Europe/Berlin)  
**Scope:** P0 UI polish + Account + Auth live path + KI BYOK + AppFlags  
**Refs:** `UI-POLISH-HAPPYPATH-V1.md`, `LIVE-AUTH-CAPTION-BYOK-V1.md`, QA G-Live GL-01..07

## Screen-ID

| ID | Screen | Path |
|----|--------|------|
| **S-63** | AccountScreen (neu) | `/more/account` |
| S-61 | SettingsScreen (erweitert: Konto → Account, KI/Captions Key) | `/more/settings` |
| S-00 | SplashAuth (live/mock) | `/auth` |
| S-60 | Paywall (benefit-first) | `/paywall` |

## Brand (interim locked)

- Primary: `#0F766E` / `Color(0xFF0F766E)` (`BrandColors.primary`)
- Pro-badge: Indigo `#4338CA` / `Color(0xFF4338CA)` (`BrandColors.proBadge`)
- Logo final: **TBD** (Belkis)

## Auth (GL-01)

- `AppEnv`: `SUPABASE_URL` + `SUPABASE_ANON_KEY` via `--dart-define` (nie im Repo)
- Wenn beide gesetzt → `WerklySupabase.initFromEnv()` + `supabase.auth` Password / Magic-Link
- Sonst → klar gelabelter **Gast / Mock**-Login (`AppFlags.mockAuth`)
- `authSessionProvider` steuert GoRouter redirect (unauth → `/auth`, auth auf `/auth` → `/planen`)

## Account (GL-02)

- E-Mail / „Gast/Mock“, Plan-Pill Free | Pro, Logout (wischt optional LLM-Key)

## KI-Key (GL-03)

- Settings „KI / Captions“: obscured TextField → Save → `flutter_secure_storage` Key **`werkly_llm_api_key`**
- UI zeigt nur masked last-4; Clear-Button; **nie** geloggt
- BYOK Request-Header: `X-Werkly-LLM-Key` (ephemer, nicht in DB) — siehe Backend contract

## Captions live/mock (GL-04 / GL-05)

| Condition | Path |
|-----------|------|
| `AppFlags.useLiveCaptions` | Edge `generate-caption` — server mode (JWT only) **oder** BYOK header if user key set |
| sonst | Local `MockCaptionGenerator` + UI Chip **„Mock“** |
| 402 / quota | Soft paywall `limit_captions` |

## AppFlags (GL-06)

| Flag | True when |
|------|-----------|
| `mockAuth` | no SUPABASE_URL+anon |
| `mockCaptions` | Supabase not configured |
| `mockStripe` | Supabase not configured |
| `useLiveCaptions` | configured && !mockCaptions |

Documented in root README.

## Paywall (GL-07)

- Headline benefit-first: „Unbegrenzte Captions & Deals“
- Primary CTA: **9,99 €/Mo**
- Soft close: **„Weiter mit Free“** + visible Close

## UI polish

- M3 theme + `AppSpacing` 16/24 + DE text theme + one primary FilledButton style
- Empty states: F1 Kalender, F2 Favoriten, F3 Hub Links, F4 Deals
- `OfflineBanner` wired via connectivity (`MainShell` + F1)

## Blockers (noch offen)

1. **Supabase-Projekt (EU)** + Migration + Edge deploy `generate-caption`
2. **Brand logo** final (Farbe interim locked)
3. Server-LLM Secret **oder** BYOK-only
4. Android Auth deep link / magic-link redirect
5. RevenueCat live purchase (Paywall CTA noch Stub)

## Secrets

Keine Secrets im Repo. `.env*` gitignored. Client nur anon + user JWT — **kein** `service_role`.

## Key paths (Mobile)

```
apps/werkly/lib/ui/theme/brand_colors.dart
apps/werkly/lib/ui/theme/app_theme.dart
apps/werkly/lib/ui/theme/app_spacing.dart
apps/werkly/lib/core/config/app_env.dart
apps/werkly/lib/core/config/app_flags.dart
apps/werkly/lib/core/auth/*
apps/werkly/lib/core/secure/llm_key_store.dart
apps/werkly/lib/features/account/account_screen.dart
apps/werkly/lib/features/settings/settings_screen.dart
apps/werkly/lib/features/auth/splash_auth_screen.dart
apps/werkly/lib/features/paywall/paywall_screen.dart
apps/werkly/lib/features/captions/data/edge_caption_client.dart
```


## G-Live checklist map (code ready)

| ID | Coverage in this PR |
|----|---------------------|
| GL-01 Auth | SplashAuth live/mock + session restore + router redirect |
| GL-02 Account | S-63 email/Gast, Free/Pro pill (Indigo), Logout |
| GL-03 KI-Key | Settings secure storage + masked last-4; never logged |
| GL-04 Caption live | `useLiveCaptions` → Edge server **or** BYOK `X-Werkly-LLM-Key`; else Mock badge |
| GL-05 Quota 402 | Existing soft-gate + Edge 402 → paywall `limit_captions` |
| GL-06 Flags | `AppFlags` + Settings Über + README |
| GL-07 Paywall | Benefit-first → 9,99 €/Mo → Weiter mit Free |
| GL-08 Security | No service_role; key only secure storage; not in git |

Device/Backend still required for full G-Live green (see Blockers).
