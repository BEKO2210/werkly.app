# F3 Link-Hub + Media Kit — Changelog

**App:** Werkly (`com.werkly.app`)  
**Scope:** US-F3-01..05 · usable UI S-30..S-34 · Backend §2.4 · Soft gate `limit_hub_branding`

## Contracts / domain

1. Local CRUD: `Hub` + ordered `HubLink` + `MediaKit` (memory + optional JSON file persist)
2. Public URL: `https://werkly.app/h/{slug}` (host configurable via `HubSlug`)
3. Free: **1 hub** + `showBranding=true` (Powered by Werkly)
4. Pro: custom slug + branding off → otherwise soft paywall `limit_hub_branding`
5. OpenAPI-aligned Edge clients + local mocks (see #8)
6. Share: `share_plus` + clipboard copy; share-ready requires ≥1 labeled link
7. Analytics S-34: 7/30d from local `track-hub-click` counts (Should)
8. Edge clients (OpenAPI `edge-functions-v1.yaml`):
   - `GET /functions/v1/public-hub?slug=` → `PublicHubDto` (`slug`, `display_name`, `links`, `show_branding`, …)
   - `POST /functions/v1/track-hub-click` `{hub_link_id}` → 204; local mock records clicks
   - Mocks: `assets/contracts/mocks/public-hub-200.json` / `404` / `track-hub-click-204.json`

## Files added / touched

### Domain
- `lib/features/hub/domain/hub_models.dart`
- `lib/features/hub/domain/hub_slug.dart`
- `lib/features/hub/domain/hub_validation.dart`
- `lib/features/hub/domain/hub_repository.dart`

### Data / API
- `lib/features/hub/data/hub_memory_store.dart`
- `lib/features/hub/data/hub_file_store.dart`
- `lib/features/hub/data/local_hub_repository.dart`
- `lib/features/hub/data/public_hub_client.dart`
- `lib/features/hub/data/track_hub_click_client.dart`
- `lib/features/hub/domain/public_hub_api.dart`
- `lib/features/hub/providers/hub_providers.dart`
- `assets/contracts/mocks/public-hub-200.json`
- `assets/contracts/mocks/public-hub-404.json`
- `assets/contracts/mocks/track-hub-click-204.json`

### UI
- `hub_editor_screen.dart` (S-30)
- `hub_link_editor_screen.dart` (S-31)
- `media_kit_editor_screen.dart` (S-32)
- `hub_preview_screen.dart` (S-33)
- `hub_analytics_screen.dart` (S-34)
- `quota_policy.dart` — `freeHubLimit`, `paywallTriggerHubBranding`
- `paywall_screen.dart` — headline for `limit_hub_branding`

### Tests / docs
- `test/features/hub/hub_slug_gate_test.dart`
- `F3-CHANGELOG.md`, `README.md`, `FILELIST.txt`

## Verify US-F3-01..05

| Story | Verify |
|-------|--------|
| US-F3-01 | S-30: name/bio/avatar placeholder + reorderable links; S-31 add/edit/delete |
| US-F3-02 | Teilen / Link kopieren → `https://werkly.app/h/{slug}`; S-33 preview mock |
| US-F3-03 | S-32 niches, platforms+followers, contact, 1–3 links, pitch; kit share URL |
| US-F3-04 | S-34 7d/30d counts list (local fake) |
| US-F3-05 | Free: branding toggle off / custom slug → `/paywall?trigger=limit_hub_branding`; Pro unlocks |
| Soft gate | Hub remains editable/shareable with branding on Free |

```bash
cd apps/werkly && flutter pub get && flutter test test/features/hub/
```
