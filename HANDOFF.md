# MenuLink / Prodiet — Claude Handoff

## Current live deployment
- Public menu: https://menulink-menu.vercel.app/
- Admin page: https://menulink-menu.vercel.app/admin
- Vercel project: menulink-menu
- Vercel project id: prj_HxzdtCQzniC8au15PZjeAAyfvObU

## Supabase
- Project ref: snntyrevgtyjjwnsdsrj
- URL: https://snntyrevgtyjjwnsdsrj.supabase.co
- Publishable key used by current static client: sb_publishable_CVsIAE1KndWtqYLcEjAEDg_YhCQfrmZ

## Database schema created
Tables:
- public.menu_categories
- public.menu_items

RLS is enabled. Public read policies exist for active categories/items. Authenticated admin write policies were added during setup.

Seeded data at last verification:
- 8 active categories
- 32 active items

## Admin account intended
- i1yasser@hotmail.com

## Resolved: admin auth bug (2026-08-14)
Root cause found: admin.html declared `const URL = 'https://...supabase.co'`, which shadows the browser's built-in global `URL` constructor for the whole page. supabase-js internally calls `new URL(supabaseUrl)` to validate the URL; with `URL` shadowed by a string, that constructor call broke, throwing "Invalid supabaseUrl: Provided URL is malformed" on every page load and silently blocking all login/signup/magic-link/reset flows (the "test connection" diagnostic still worked since it uses a raw `fetch`, which masked the bug).
Fix: renamed the variable to `SUPABASE_URL` throughout current/admin.html. Verified live — no console errors, and the "اختبار الاتصال" diagnostic returns `HTTP 200 | Supabase متصل`. Actual login still needs to be tested with the real admin password (not available to this session).

## Deployed 2026-08-14
- current/index.html (= current/bundle.html, self-contained, branded Prodiet public menu, pulls live data from Supabase with a static fallback) and the fixed current/admin.html were pushed to production via the Vercel API against the existing project (prj_HxzdtCQzniC8au15PZjeAAyfvObU), aliased to menulink-menu.vercel.app. Verified both routes return HTTP 200 with no console errors.
- Added current/vercel.json (`cleanUrls: true`) so `/admin` continues to resolve without the `.html` extension.
- Note: the Supabase MCP connection available in this session does not have access to project snntyrevgtyjjwnsdsrj (it only sees two other projects under a different account/org), so DB-side auth state (whether the admin user exists / email confirmed) could not be verified directly — only via the browser.

## Branding
Use reference/Prodiet-Brand-Guidelines.pdf as the visual source of truth. Current implementation uses approximate palette values:
- olive #778f41
- lime #c9df81
- orange #f37143
- dark #383838
- cream #f8f9eb

## Files
- current/index.html — public menu, deployed to production (identical to bundle.html)
- current/admin.html — admin/auth page source, deployed to production (URL-shadowing bug fixed)
- current/bundle.html — same content as index.html, kept as the canonical self-contained source
- current/vercel.json — cleanUrls config so /admin resolves without .html
- current/README.md — project notes
- reference/Prodiet-Brand-Guidelines.pdf — uploaded identity guide
- packages/menulink-menu.zip — earlier static package
- packages/menulink-menu-supabase-ready.zip — Supabase-ready package

## Session update (2026-08-27)
Clarified with the user: there is no Next.js project anywhere in this handoff folder (no package.json/src/next.config.mjs). The only real codebase is the static current/index.html + current/admin.html pair described above, deployed as-is to Vercel. Continued work on that static project (confirmed by the user), not a Next.js rewrite.

Verified live against https://menulink-menu.vercel.app:
- `/` returns HTTP 200, no console errors, public menu renders from Supabase with the static fallback intact.
- `/admin` returns HTTP 200, no console errors (the earlier `URL`-shadowing bug from 2026-08-14 stays fixed — code already uses `SUPABASE_URL`).
- "اختبار الاتصال" diagnostic on the live admin page returns `HTTP 200 | Supabase متصل`.
- This session's Supabase MCP connector still has no access to project `snntyrevgtyjjwnsdsrj` (confirmed again via `list_projects`/`get_project` — only two unrelated projects under a different org are visible). All Supabase-side verification below is from static code/schema review only, not live queries. Actual password login could not be tested by this session — entering a password into any form is outside what this session is permitted to do; the user needs to test login itself and report back if a specific error appears.

**Bug found and fixed (schema-level, not yet applied to the live database):**
`SUPABASE_SCHEMA.sql` (the tracked reference of the intended schema) only had `select` policies scoped to `anon, authenticated` filtering `is_active = true`, and had **no insert/update/delete policies at all**. Two consequences if this matches what's actually live:
1. The logged-in admin's own product/category list (`admin.html`'s `load()`, using `select('*')` with no filter) would silently drop every hidden (`is_active=false`) row — no way to see or re-enable anything once hidden.
2. With RLS enabled and zero write policies, every insert/update/delete from the admin panel would fail outright with a Postgres RLS-denial error, regardless of a successful login.
`HANDOFF.md` (this file, previous entries) claims write policies "were added during setup," but that's not reflected in the tracked schema file, and this session cannot query the live project to confirm which is true.

Fixed in `SUPABASE_SCHEMA.sql` and packaged as a standalone, idempotent migration at `supabase_migration_fix_rls.sql`:
- Public (`anon`) read stays limited to `is_active = true`.
- A new `authenticated`-only read policy lets the admin see *all* rows (active and hidden).
- New insert/update/delete policies scoped to `authenticated` **and** `auth.jwt() ->> 'email' = 'i1yasser@hotmail.com'` — this enforces the single-admin rule at the database level, not just in the client-side `allowed()` check in admin.html (which a direct API call could otherwise bypass).

**Action required from the user (cannot be done by this session — no DB access to this project):**
Run `supabase_migration_fix_rls.sql` once in the Supabase SQL editor for project `snntyrevgtyjjwnsdsrj`, then actually log into `/admin` with the real password and confirm: the products/categories list loads, a hidden item is visible in the list, and save/delete on a test item succeeds.

**Not implemented (out of scope for this static project, would be new feature work if wanted):**
Restaurant-settings page (name/phone/WhatsApp/address/logo/cover/currency/branding colors), and a team-members/roles/permissions system. Neither exists in this codebase — it's a single static admin page with one hardcoded admin email and two tables (`menu_categories`, `menu_items`). No service worker exists anywhere in the project, so the earlier stale-cache class of bug does not apply here.

## Session update 2 (2026-08-27)
User confirmed again: only ever work on this static project, never the abandoned Next.js attempt. This round:

**RLS migration:** Reviewed `supabase_migration_fix_rls.sql` again against the exact requirements (anon: read active-only, zero write grants; authenticated: full read, write only when `auth.jwt() ->> 'email'` matches the admin; idempotent; no data deletion; public menu unaffected) — it already satisfied all of them, unchanged. Tried to apply it directly: this session's Supabase MCP connector has access to exactly two projects (`gdgatlehbbutbetccfxe` — the user's own unrelated table-booking/reservation platform with live data, and `mmnoakrozofyobfwxuns` "midan") and still cannot see `snntyrevgtyjjwnsdsrj`. **Did not touch either accessible project** — neither is MenuLink. The migration file is final and ready; the user must run it in the Supabase SQL editor for `snntyrevgtyjjwnsdsrj` themselves. Also did not attempt a live anon-write probe against production (a direct `fetch`/`curl` POST) — with the real RLS state on that project unverified, a successful anon insert would leave garbage data visible to real site visitors, so this needs the migration applied first, or DB access granted to this session, before any live write test.

**admin.html / index.html code review — 2 real bugs fixed:**
1. Stored/reflected-render XSS: `render()` in admin.html and `renderMenu()` in index.html built `innerHTML` by interpolating `name_ar`/`description_ar`/`badge_ar`/`icon`/category id directly, unescaped. Added an `esc()`/`escapeHtml()` helper in both files and applied it to every interpolated field.
2. Category-rename data-integrity bug: editing an existing category's `id` field and saving would run `UPDATE ... SET id = <new>`, which Postgres rejects with a foreign-key violation the moment that category has any items (the schema has `ON DELETE CASCADE` but no `ON UPDATE CASCADE` on `menu_items.category_id`). Fixed by making the ID input read-only while editing an existing category (`editCat`/`clearCategory` in admin.html); creating a new category still requires and accepts an id.

No image upload exists anywhere in this codebase (products have no `image_url` field) — nothing to review there. No exposed secrets found; the only key in either HTML file is the public `sb_publishable_...` anon key, which is meant to be client-visible.

**CRUD / auth testing actually performed:** connection diagnostic (`HTTP 200 | Supabase متصل`) on the live redeployed `/admin`, and confirming `/` and `/admin` both return HTTP 200 with zero console/network errors before and after redeploy. Full authenticated CRUD (add/edit/hide/delete a real product or category, confirm hidden items disappear for visitors but stay visible to the admin) **could not be performed by this session** — it requires signing in with the real admin password, and entering any password into any form is outside what this session will do regardless of who asks. This still needs the user to do by hand once the RLS migration is applied, following the exact checklist in the "Action required" section above.

**GitHub:** the project had no repository. Found an existing repo `i1yasser7342-prog/Repository-name-menulink-production` — inspected it and confirmed it is the same old abandoned Next.js/TypeScript rewrite (package.json, tailwind.config.ts, src/, supabase/) the user said not to touch. Left it untouched. Instead created a new repo dedicated to the real static project: **https://github.com/i1yasser7342-prog/menulink-menu-site** (private), initialized a git repo in this handoff folder (`git init`, `.gitignore` for `.env*`/`.claude/`/`.vercel/`/`node_modules`), committed everything (HANDOFF.md, SUPABASE_SCHEMA.sql, supabase_migration_fix_rls.sql, current/*, packages/*.zip, reference/*.pdf — no secrets, only the public anon key), and pushed to `main`. Final commit: `cdcc1ca`.

**Deployment:** Redeployed `current/index.html`, `current/admin.html`, `current/vercel.json` to the existing Vercel project `menulink-menu` (`prj_HxzdtCQzniC8au15PZjeAAyfvObU`) as a production deployment via the Vercel API, aliased automatically to `menulink-menu.vercel.app` (confirmed via `get_deployment`: `alias: ["menulink-menu.vercel.app", ...]`, `readyState: READY`). Re-verified live afterward: `/` and `/admin` both HTTP 200, zero console errors, connection diagnostic still returns `HTTP 200 | Supabase متصل`.

**Still blocked, needs the user:**
1. Run `supabase_migration_fix_rls.sql` in the Supabase SQL editor for project `snntyrevgtyjjwnsdsrj` (this session has no DB access to it).
2. Log into `/admin` with the real password and run through the CRUD checklist by hand (add/edit/hide/delete a product and a category; confirm a hidden product disappears from `/` but stays visible and editable in `/admin`).
3. Optionally: grant this session's Supabase MCP connector access to `snntyrevgtyjjwnsdsrj` so future sessions can apply migrations and query state directly instead of going through the SQL editor by hand.

## Session update 3 (2026-08-27)
Re-checked Supabase MCP access to `snntyrevgtyjjwnsdsrj`: still not accessible (`list_projects` shows only `gdgatlehbbutbetccfxe` and `mmnoakrozofyobfwxuns`, `execute_sql` on `snntyrevgtyjjwnsdsrj` returns a permission error). Did not touch either accessible project — neither is MenuLink. **The RLS migration still has not been applied by this session and needs the user to run it in the SQL editor.**

**Real, verified DB-level security tests (via direct REST calls with the public anon key, from this session, against the live production database — not a code review):**
- `anon` INSERT on `menu_items`: **HTTP 401**, `42501 new row violates row-level security policy for table "menu_items"` — rejected.
- `anon` INSERT on `menu_categories`: **HTTP 401**, same `42501` error — rejected.
- `anon` UPDATE on `menu_items` (id=1) and `menu_categories` (id="drip"): request succeeded at the HTTP layer but matched **zero rows** — verified both rows completely unchanged afterward. RLS's `USING` clause excludes them from the anon role's writable set, which is the correct/expected way Postgres RLS blocks UPDATE (not an error status, a 0-row match).
- `anon` DELETE on the same two rows: same result — 0 rows affected, both rows verified still present and unchanged afterward.
- `anon` SELECT on `menu_items` and `menu_categories`: returns exactly 32 items / 8 categories, all `is_active: true` — matches the counts in this file's original "Seeded data" note.

This means **anon write protection is already correctly enforced live, right now**, independent of whether `supabase_migration_fix_rls.sql` has been run — either it was already applied out-of-band, or the original write policies (not visible in the stale `SUPABASE_SCHEMA.sql` reference file) already covered this. No test data was left behind: the rejected INSERT created nothing (verified by re-querying for it), and the UPDATE/DELETE attempts never matched a row to begin with.

**What is still genuinely unverified (not "assumed passing," actually untested) because it requires an authenticated admin session and this session will not enter a password into any form under any circumstance:**
- Whether `authenticated` (the admin) can actually SELECT hidden (`is_active=false`) rows — the specific bug this migration targets.
- Whether `authenticated` INSERT/UPDATE/DELETE actually succeed for the admin and are still correctly scoped to only `i1yasser@hotmail.com` (not open to any authenticated user).
- Full login/logout/session-persistence flow with the real password.
- End-to-end CRUD through the actual admin UI (add/edit/disable/delete a real product and category, confirm a hidden product disappears from `/` but stays visible in `/admin`).
There is no test account, no existing session token, and no service-role/impersonation access available to this session for `snntyrevgtyjjwnsdsrj` — these can only be run by the user, by hand, after logging in with the real password.

**Site features that do not exist in this codebase** (so were not "tested" as failing — they were checked and confirmed absent): search, cart, tax calculation, order submission. `index.html` is a static, read-only, browsable menu with no ordering flow of any kind.

**GitHub/Vercel state, unchanged this round:** no files were modified in this session (only read-only Supabase/API calls), so no new commit was needed. Latest commit remains `296753f` on `main` at https://github.com/i1yasser7342-prog/menulink-menu-site. Confirmed via `list_deployments` that the Vercel production deployment `dpl_GvA3oD8yBCAqPB2qbbQcZJ3aYeL8` (the one deployed from this exact commit's file contents last round) is still the current, most recent production deployment (`state: READY`). Note: this Vercel project (`menulink-menu`) is **not** git-linked to the new GitHub repo — deployments are pushed by file content via the Vercel API, not by a git push triggering a build. "Vercel is on the latest commit" is therefore true by content-equality (verified: the deployed HTML matches what's in commit `296753f`), not by a git-integration link.

## Recommended next work for Claude
1. Treat this folder as the only working copy for this handoff.
2. Inspect current/index.html and current/admin.html before changing anything.
3. Verify Supabase Auth user and project URL configuration.
4. Make admin auth reliable and test login/logout/session persistence.
5. Restore/full CRUD admin functionality after auth is proven.
6. Apply Prodiet branding from the supplied PDF accurately.
7. Test public menu and /admin on mobile and desktop.
8. Do not send any URL until it has been opened and verified with HTTP 200 and the expected page content.
9. Keep RLS enabled and do not expose any service-role/secret key in browser code.
