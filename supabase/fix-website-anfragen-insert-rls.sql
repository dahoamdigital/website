-- Bei „new row violates row-level security“ für website_anfragen im SQL Editor ausführen.

grant insert on public.website_anfragen to anon, authenticated;
grant insert, select, update, delete on public.website_anfragen to authenticated;

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

-- Kontaktformular: zusätzlich supabase/rpc-submit-website-anfrage.sql ausführen
-- (ohne RPC schlägt .insert().select('id') an RLS fehl, weil RETURNING wie SELECT wirkt).
-- Admin (Erledigt/Löschen): supabase/website-anfragen-status-migration.sql
