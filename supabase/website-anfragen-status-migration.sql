-- Einmal im SQL Editor: bestehende Tabelle website_anfragen um Status + Admin-Update/Delete erweitern.

alter table public.website_anfragen add column if not exists status text;
update public.website_anfragen set status = 'offen' where coalesce(status, '') not in ('offen', 'erledigt');
alter table public.website_anfragen alter column status set default 'offen';
alter table public.website_anfragen alter column status set not null;

alter table public.website_anfragen drop constraint if exists website_anfragen_status_check;
alter table public.website_anfragen add constraint website_anfragen_status_check check (status in ('offen', 'erledigt'));

alter table public.website_anfragen add column if not exists erledigt_am timestamptz;

grant insert, select, update, delete on public.website_anfragen to authenticated;
grant insert on public.website_anfragen to anon;

drop policy if exists "website_anfragen_admin_update" on public.website_anfragen;
create policy "website_anfragen_admin_update"
  on public.website_anfragen for update
  to authenticated
  using (coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin')
  with check (coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin');

drop policy if exists "website_anfragen_admin_delete" on public.website_anfragen;
create policy "website_anfragen_admin_delete"
  on public.website_anfragen for delete
  to authenticated
  using (coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin');
