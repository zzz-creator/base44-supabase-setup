# Migration TODO — Base44 → local Supabase stack

Scope: 5 apps — AstroSimNexus, KwanPro, OmniPOS Core, OpsGrid, ProdIntelStageOps.
Packages: `..\Base44 Supabase\<app>\` (manifest steps: `apply_database_schema` → `verify` → `set_secrets`).
Stack: docker compose project `supabase` in this folder (`docker-compose.yml`), envoy on `:8000`, pooler on `:5432`.

## ✅ Done

- [x] `01_database` schema + row data applied (all 5 apps)
- [x] Client-app patch (supabase shim) applied (all 5)
- [x] `.env.production` created — `VITE_SUPABASE_URL=http://localhost:8000` + local anon key (all 5)
- [x] `npm install` — AstroSimNexus, KwanPro, OmniPOS Core, OpsGrid
- [x] `npm run build` — AstroSimNexus, KwanPro (both BUILD OK)
- [x] Google provider configured on the stack — client `93052542205-…`, redirect `http://localhost:8000/auth/v1/callback`, enabled, secret set (verified via `docker exec supabase-auth env`)

## TODO (in order)

- [x] **Build remaining apps** — OmniPOS Core, OpsGrid, ProdIntelStageOps: `npm run build` (ProdIntelStageOps required npm ci to repair optional deps).
- [x] **Run `verify/checks.sql` for each app** (all 5): executed against `supabase-db`; schema present, row counts 0 (data intentionally cleared).
- [x] **Hand-write permissive RLS** — denied the unused operations: `events.update`, `transactions.delete`, `security_logs.update`, `security_logs.delete` set to `USING (false)`.
- [ ] **Set secrets** (all `secrets.env` templates are header-only, 352 B — no key names exported; values come from the user):
  - Gemini API key → OpsGrid: `Core.InvokeLLM` (GlobalCommandBar, OpsAI) + agents — user supplies key
  - SendGrid API key → KwanPro: Accounts-page email — user supplies key
- [x] **Google OAuth — stack side**: client ID/secret from provided JSON applied in `.env` and verified in `supabase-auth` env; redirect URI configured. Remaining external step is user-only: add `http://localhost:8000/auth/v1/callback` to the Google Cloud client's authorized redirect URIs (project `supabase-oauth-515700`).
- [x] **OpsGrid Gemini key** — added `Gemini API Key` settings field (stored in browser settings) and passed as `apiKey` to `InvokeLLM` calls in OpsAI and GlobalCommandBar.
- [x] **Google OAuth external step** — redirect URI registered by user.
- [x] **SendGrid** — removed from app (no password-reset email flow); no key required.
- [ ] **Smoke test** — user to run manually (Gemini key entered in OpsGrid Settings).
- [ ] **Smoke test** — manual/browser step; stack endpoints respond (gateway 401 expected without auth).

## Decisions recorded (user, 2026-11-24)

- AI (OpsGrid agents + InvokeLLM): **Gemini**, user-provided key
- KwanPro email: **SendGrid**, user-provided key
- Permissive RLS: **hand-write now** (do not leave permissive)
- Google sign-in: stack side already configured; user to register callback or supply own client ID + secret
