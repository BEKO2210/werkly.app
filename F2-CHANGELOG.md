# F2 AI Caption & Hook Generator — Changelog

**App:** Werkly (`com.werkly.app`)  
**Scope:** US-F2-01..04 · usable UI S-20/S-21/S-22 · contract `GENERATE-CAPTION-V1.md`

## Contracts

1. `POST /functions/v1/generate-caption` + JWT (`EdgeCaptionClient`)
2. Request: prompt 1–500, `language` de|en, optional tone/platform (`ig|tiktok|yt|other`)
3. 200: ≥3 captions + ≥1 hook, `quota {used, limit, plan, period YYYY-MM}`
4. Free **10/mo** → soft gate + 402 `limit_captions` → `/paywall?trigger=limit_captions`
5. Local `MockCaptionGenerator` — same JSON shapes as `contracts/mocks/*.json` (+ assets copy)
6. Policy reject: empty / contains `BLOCK` (case-insensitive) → inline error, no API call
7. Online required for generate (connectivity check); no offline queue
8. Regenerate = new `generation_id`, counts quota
9. Edge if `WerklySupabase.isConfigured`, else Mock with visible provider note; Edge hard fail → Retry + Klartext

## Files added / touched

### Domain
- `lib/features/captions/domain/caption_models.dart`
- `lib/features/captions/domain/caption_validation.dart`
- `lib/features/captions/domain/caption_repository.dart`

### Data / API
- `lib/features/captions/data/mock_caption_generator.dart`
- `lib/features/captions/data/edge_caption_client.dart`
- `lib/features/captions/data/caption_memory_store.dart`
- `lib/features/captions/data/local_caption_repository.dart`
- `lib/features/captions/providers/caption_providers.dart`
- `assets/contracts/mocks/*.json`

### UI
- `caption_home_screen.dart` (S-20)
- `caption_result_screen.dart` (S-21)
- `caption_favorites_screen.dart` (S-22)
- `widgets/caption_variant_card.dart`
- `post_editor_screen.dart` — `CaptionPrefill` via go_router `extra`
- `app_router.dart`, `paywall_screen.dart`, `quota_policy.dart`, `quota_banner.dart`

### Tests / docs
- `test/features/captions/caption_validation_quota_test.dart`
- `F2-CHANGELOG.md`, `README.md`, `FILELIST.txt`

## Verify US-F2-01..04

| Story | Verify |
|-------|--------|
| US-F2-01 | S-20: topic + DE\|EN + optional tone/platform → Generieren → S-21 ≥3 captions + ≥1 hook |
| US-F2-02 | Copy / Favorit / **In Kalender** → PostEditor caption prefilled |
| US-F2-03 | Regenerieren → new id, quota +1 |
| US-F2-04 | S-22 favorites list, copy, In Kalender |
| Soft gate | used≥10 Free → `/paywall?trigger=limit_captions`; results remain readable |
| Safety | empty / `BLOCK` → inline error, no generate |

```bash
cd apps/werkly && flutter pub get && flutter test test/features/captions/
```
