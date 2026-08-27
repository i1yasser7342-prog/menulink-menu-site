-- Run this once in the Supabase SQL editor for project snntyrevgtyjjwnsdsrj
-- (Project Settings -> SQL Editor). Safe to re-run: drops and recreates only
-- the policies it touches, does not touch data.
--
-- What this fixes:
-- 1. The public read policies were scoped to "anon, authenticated", which
--    means the logged-in admin ALSO only ever sees is_active=true rows.
--    Result: any hidden product/category silently disappears from the admin
--    panel with no way to find it again and re-enable it.
-- 2. There were no INSERT/UPDATE/DELETE policies at all on either table.
--    RLS is enabled with no write policy = every write is denied by
--    default. This means the admin panel's "save/delete" actions would
--    fail with a Postgres RLS error even after a successful login,
--    UNLESS equivalent policies were already added by hand in the
--    dashboard (unverified — this session's Supabase connector does not
--    have access to this project to check). Running this makes the
--    intended state explicit and idempotent either way.

drop policy if exists "Public can read active menu categories" on public.menu_categories;
drop policy if exists "Public can read active menu items" on public.menu_items;
drop policy if exists "Admin can read all menu categories" on public.menu_categories;
drop policy if exists "Admin can read all menu items" on public.menu_items;
drop policy if exists "Admin can insert menu categories" on public.menu_categories;
drop policy if exists "Admin can update menu categories" on public.menu_categories;
drop policy if exists "Admin can delete menu categories" on public.menu_categories;
drop policy if exists "Admin can insert menu items" on public.menu_items;
drop policy if exists "Admin can update menu items" on public.menu_items;
drop policy if exists "Admin can delete menu items" on public.menu_items;

create policy "Public can read active menu categories"
on public.menu_categories for select
to anon
using (is_active = true);

create policy "Public can read active menu items"
on public.menu_items for select
to anon
using (is_active = true);

create policy "Admin can read all menu categories"
on public.menu_categories for select
to authenticated
using ((auth.jwt() ->> 'email') = 'i1yasser@hotmail.com');

create policy "Admin can read all menu items"
on public.menu_items for select
to authenticated
using ((auth.jwt() ->> 'email') = 'i1yasser@hotmail.com');

create policy "Admin can insert menu categories"
on public.menu_categories for insert
to authenticated
with check ((auth.jwt() ->> 'email') = 'i1yasser@hotmail.com');

create policy "Admin can update menu categories"
on public.menu_categories for update
to authenticated
using ((auth.jwt() ->> 'email') = 'i1yasser@hotmail.com')
with check ((auth.jwt() ->> 'email') = 'i1yasser@hotmail.com');

create policy "Admin can delete menu categories"
on public.menu_categories for delete
to authenticated
using ((auth.jwt() ->> 'email') = 'i1yasser@hotmail.com');

create policy "Admin can insert menu items"
on public.menu_items for insert
to authenticated
with check ((auth.jwt() ->> 'email') = 'i1yasser@hotmail.com');

create policy "Admin can update menu items"
on public.menu_items for update
to authenticated
using ((auth.jwt() ->> 'email') = 'i1yasser@hotmail.com')
with check ((auth.jwt() ->> 'email') = 'i1yasser@hotmail.com');

create policy "Admin can delete menu items"
on public.menu_items for delete
to authenticated
using ((auth.jwt() ->> 'email') = 'i1yasser@hotmail.com');
