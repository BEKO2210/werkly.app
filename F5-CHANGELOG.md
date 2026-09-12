# F5 Stripe Monetize light — Changelog

**App:** Werkly (`com.werkly.app`)  
**Scope:** US-F5-01..05 · usable UI S-50..S-54 · Soft gate `limit_stripe_products`  
**Contract:** `novaforge-product/contracts/STRIPE-CONNECT-CHECKOUT-MOBILE-V1.md`

## Backend / Billing alignment

1. Connect enum **`none` | `pending` | `active` | `restricted`** (OpenAPI; not `not_started`)
2. **Onboard → `active` before** products / tips / checkout
3. `POST /stripe-connect-onboard` → `{url, stripe_connect_status}`; refresh after return
4. `POST /stripe-checkout` only if `active`; body `kind` product|tip + `id`; tip needs `tip_amount_cents` ≥ 100
5. **403** `connect_inactive` → S-51 · **402** `quota_exceeded` → paywall `limit_stripe_products`
6. Free: **1 offer (Tip XOR 1 Produkt)** · Pro: Tip + bis 10 Produkte
7. **Orders GET only** (S-54); writes via webhook / mock simulate
8. **Fee-bps** `plan_limits`: Free **1000 (10 %)** / Pro **500 (5 %)**
9. UI-Copy: **RC Pro 9,99 €/Mo ≠ Creator-Sales (Stripe)**
10. No Stripe secrets; `X-Werkly-Mock` + local fixtures

## UX (baked)

| Screen | ID | Path | UX |
|--------|----|------|-----|
| MonetizeHomeScreen | S-50 | `/more/monetize` | Connect card, product/tip/sales CTAs, RC ≠ Stripe note |
| StripeConnectScreen | S-51 | `/more/monetize/connect` | Status, Start/Continue (`url_launcher` mock), Refresh pending→active |
| ProductEditorScreen | S-52 | `/more/monetize/product` | Name, Preis EUR, Unlock, live, Hub attach |
| TipLinkEditorScreen | S-53 | `/more/monetize/tip` | Suggested amounts, live, Hub attach |
| SalesListScreen | S-54 | `/more/monetize/sales` | orders GET + simulate sale · de-DE EUR |
| ComingSoon | S-70 | `/more/monetize/soon` | **Redirect → S-50** (never the only path) |

## Files added / touched

### Domain
- `lib/features/monetize/domain/monetize_models.dart`
- `lib/features/monetize/domain/monetize_validation.dart`
- `lib/features/monetize/domain/monetize_repository.dart`
- `lib/features/monetize/domain/stripe_api.dart`

### Data / API
- `lib/features/monetize/data/monetize_memory_store.dart` + `monetize_file_store.dart`
- `lib/features/monetize/data/local_monetize_repository.dart`
- `lib/features/monetize/data/stripe_connect_client.dart` — POST onboard + status refresh
- `lib/features/monetize/data/stripe_checkout_client.dart` — POST checkout 402/403
- `lib/features/monetize/data/orders_client.dart` — GET only
- `lib/features/monetize/providers/monetize_providers.dart`
- `assets/contracts/mocks/stripe-*.json`

### UI
- S-50..S-54 usable; S-70 redirect
- `quota_policy.dart` — XOR, fee-bps, `limit_stripe_products`
- `paywall_screen.dart`, `settings_screen.dart` (Abo ≠ Verkäufe)
- Hub attach `HubLink` type product|tip + `refId`

### Tests / docs
- `test/features/monetize/monetize_quota_connect_test.dart`
- `F5-CHANGELOG.md`, `README.md`, `FILELIST.txt`

## Verify US-F5-01..05

| Story | Verify |
|-------|--------|
| US-F5-01 | S-51: Start onboard mock URL, Refresh → active |
| US-F5-02 | S-52: product name/price/unlock; live needs Connect active |
| US-F5-03 | S-53: tip amounts; XOR vs product on Free |
| US-F5-04 | Attach to Hub creates type product|tip + refId |
| US-F5-05 | S-54 sales list de-DE EUR after simulate sale |
| Soft gate | Free 2nd product → `/paywall?trigger=limit_stripe_products` |
| 403 | Checkout without Connect → S-51 |

```bash
cd apps/werkly && flutter pub get && flutter test test/features/monetize/
```
