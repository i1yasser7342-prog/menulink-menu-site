-- STATUS: APPLIED to project snntyrevgtyjjwnsdsrj on 2026-08-27, via the
-- Supabase Dashboard SQL Editor (verified logged-in browser session), and
-- verified against the live database afterward. This file is now a record
-- of the actual live policy set, not a pending script.
--
-- What was found already live (8 policies, not present in this repo's
-- history — added out-of-band at some earlier point):
--   - "Public can read active menu categories/items" (anon, SELECT,
--     is_active = true)
--   - "Admin can insert/update/delete menu categories/items"
--     (authenticated, gated by is_menu_admin())
--   - function public.is_menu_admin():
--       select coalesce((auth.jwt() ->> 'email') = 'i1yasser@hotmail.com', false)
--
-- The one gap: the SELECT policy above was scoped to BOTH anon and
-- authenticated, so the logged-in admin could only ever see is_active=true
-- rows too -- hidden products/categories were invisible even to admin, with
-- no way to re-enable them from the admin panel. Fixed by adding two new,
-- additive SELECT policies for authenticated admins (below). Nothing was
-- dropped, no data was touched, and the anon-facing read policy is
-- untouched.
--
-- Verified live (via SQL Editor, real role/JWT impersonation, not a code
-- review) after applying:
--   - anon: SELECT returns is_active=true rows only; INSERT rejected
--     (42501); UPDATE/DELETE match 0 rows (blocked).
--   - authenticated as a random non-admin email: INSERT rejected (42501)
--     -- confirms write access is NOT open to all authenticated users.
--   - authenticated as the real admin email: sees hidden rows; full
--     insert/update(rename+price)/toggle is_active/delete cycle succeeds
--     on a real (test) row; anon correctly could not see it while hidden
--     and could see it once re-activated.
--   - All test rows (one menu_items row, one menu_categories row) were
--     deleted afterward; verified 0 leftover test rows and exact original
--     counts (32 items / 8 categories) restored.

create policy "Admin can read all menu categories"
on public.menu_categories for select
to authenticated
using (is_menu_admin());

create policy "Admin can read all menu items"
on public.menu_items for select
to authenticated
using (is_menu_admin());
