-- Bei „new row violates row-level security“ für website_anfragen im SQL Editor ausführen.

grant insert on public.website_anfragen to anon, authenticated;
grant select on public.website_anfragen to authenticated;

drop policy if exists "website_anfragen_anon_insert" on public.website_anfragen;
drop policy if exists "website_anfragen_authenticated_insert" on public.website_anfragen;
drop policy if exists "website_anfragen_public_insert" on public.website_anfragen;

create policy "website_anfragen_anon_insert"
  on public.website_anfragen for insert
  to anon
  with check (true);

create policy "website_anfragen_authenticated_insert"
  on public.website_anfragen for insert
  to authenticated
  with check (true);
