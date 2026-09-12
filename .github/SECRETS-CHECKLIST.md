# Werkly — GitHub Secrets & Environments Checklist

**Repo:** https://github.com/BEKO2210/werkly.app  
**Package:** `com.werkly.app`  
**Risk:** Repo is currently **public** — never commit keystores, SA JSON, DSNs-with-auth, or `.env`. Prefer **private** before storing anything sensitive in Actions history beyond encrypted secrets.

**Production:** only via `promote.yml` + Environment `play-production` (required reviewers: Belkis + Stabschef).

---

## 1) GitHub Environments (Settings → Environments)

| Environment | Required reviewers | Used by |
|-------------|-------------------|---------|
| `play-internal` | optional (Release) | `release-internal.yml` |
| `play-closed` | Release or Stabschef | `promote.yml` → closed |
| `play-production` | **Belkis + Stabschef** | `promote.yml` → production |

Wait timer on `play-production`: 5–10 min recommended.

---

## 2) Repository / Environment Secrets

| Secret | Env | Purpose |
|--------|-----|---------|
| `PLAY_SERVICE_ACCOUNT_JSON` | play-* | Play Developer API (Release Manager, least privilege) |
| `ANDROID_KEYSTORE_BASE64` | play-internal | Upload keystore (after Mobile leaves debug signing) |
| `ANDROID_KEYSTORE_PASSWORD` | play-internal | |
| `ANDROID_KEY_ALIAS` | play-internal | |
| `ANDROID_KEY_PASSWORD` | play-internal | |
| `SENTRY_AUTH_TOKEN` | play-internal (+ optional repo) | `sentry-cli` releases |
| `SENTRY_DSN_INTERNAL` | play-internal | dart-define for internal builds |
| `SUPABASE_URL_STAGING` | play-internal | staging/internal backend |
| `SUPABASE_ANON_KEY_STAGING` | play-internal | anon only — never service role in app CI |

## 3) Variables

| Variable | Value (example) |
|----------|-----------------|
| `SENTRY_ORG` | TBD with Belkis |
| `SENTRY_PROJECT` | `werkly-android` (TBD) |

---

## 4) Before first Internal upload

- [ ] Repo visibility decision (private recommended)
- [ ] Play App Signing + upload key (replace scaffold debug signing)
- [ ] Service account linked to Play Console
- [ ] Environments created + production reviewers set
- [ ] Sentry project exists; test event from internal build
- [ ] Workflows copied to `.github/workflows/` on `main` (from `release/github-workflows/`)
- [ ] QA Gate-Report process linked to versionCode

## 5) Explicit non-goals until Freigabe

- No Production track upload
- No auto-promote from tags/schedules
- No Stripe **live** keys in any CI env for MVP internal
