# F4 Deal-Tracker light — Changelog

**App:** Werkly (`com.werkly.app`)  
**Scope:** US-F4-01..05 · usable UI S-40..S-42 · Soft gate `limit_deals` · CSV Pro via `GET deals-export`

## Backend contract alignment

1. Table **`deals`** + **soft-delete** (`deleted_at`)
2. Status enums: `inquiry` | `negotiation` | `won` | `invoiced` | `lost`  
   DE UI: Anfrage → Verhandlung → Gewonnen → Abgerechnet / Verloren
3. **Open** = status ≠ `invoiced`|`lost` (and not soft-deleted)
4. Free: **max 5 open** → soft paywall `limit_deals`
5. Amounts: `amount_cents` + currency **EUR**
6. CSV Pro: Edge `GET /functions/v1/deals-export` (OpenAPI client) + **local CSV fallback**
7. Tax disclaimer: „Rechnung selbst / Steuerberater“ — **keine Buchhaltung**

## Contracts / domain

1. Local CRUD: `Deal` (memory + optional JSON file persist `werkly_deals.json`)
2. Soft-delete tombstones kept for sync; list/get hide deleted
3. Fields: Brand, Titel, Betrag EUR (`amountCents`), Status, due, notes (+ hubId/mediaKitId)
4. Sync stub comments for Supabase `deals` columns (not wired)

## UX (baked)

| Screen | ID | Path | UX |
|--------|----|------|-----|
| DealListScreen | S-40 | `/deals` | Cards brand/title/EUR de-DE/status pill/due · status filter · brand search · QuotaBanner open/5 · FAB · empty CTA · disclaimer |
| DealEditorScreen | S-41 | `/deals/new`, `/deals/:id` | Fields + status pipeline chips · save/soft-delete · soft gate on 6th open |
| DealExportScreen | S-42 | `/deals/export` | Pro soft gate · `DealsExportClient` (Edge or local CSV) · copy/share · tax disclaimer |

## Files added / touched

### Domain
- `lib/features/deals/domain/deal_models.dart` — + `deletedAt`, Backend status enums
- `lib/features/deals/domain/deal_validation.dart`
- `lib/features/deals/domain/deal_csv.dart`
- `lib/features/deals/domain/deal_repository.dart`
- `lib/features/deals/domain/deals_export_api.dart`

### Data / API
- `lib/features/deals/data/deal_memory_store.dart` — softDelete
- `lib/features/deals/data/deal_file_store.dart`
- `lib/features/deals/data/local_deal_repository.dart`
- `lib/features/deals/data/deals_export_client.dart` — GET deals-export + local fallback
- `lib/features/deals/providers/deal_providers.dart`
- `assets/contracts/mocks/deals-export-200.json`
- `assets/contracts/mocks/deals-export-402.json`

### UI
- `deal_list_screen.dart` (S-40)
- `deal_editor_screen.dart` (S-41)
- `deal_export_screen.dart` (S-42)
- `widgets/deal_card.dart`, `widgets/deal_status_pill.dart`
- `quota_policy.dart` — `freeOpenDeals`, `paywallTriggerDeals`, `paywallTriggerDealExport`
- `paywall_screen.dart` — headlines for `limit_deals` / `feature_deal_export`

### Tests / docs
- `test/features/deals/deal_quota_csv_test.dart`
- `F4-CHANGELOG.md`, `README.md`, `FILELIST.txt`

## Verify US-F4-01..05

| Story | Verify |
|-------|--------|
| US-F4-01 | S-41: Brand, Titel, Betrag EUR, Status pipeline, due, notes |
| US-F4-02 | S-40: list cards + filter + search; open counter |
| US-F4-03 | Free blocked at 6th open → `/paywall?trigger=limit_deals`; soft-delete frees slot |
| US-F4-04 | S-42: Pro CSV via deals-export client / local fallback; Free soft-gated |
| US-F4-05 | Disclaimer on list/editor/export — no bookkeeping claims |
| Soft gate | Existing open deals remain editable/readable on Free |

```bash
cd apps/werkly && flutter pub get && flutter test test/features/deals/
```
