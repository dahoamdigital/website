-- Einmal im SQL Editor ausführen, falls nur die alte „anon“-Insert-Policy existiert
-- und eingeloggte Besucher den Fehler „new row violates row-level security“ bekommen.

drop policy if exists "website_anfragen_anon_insert" on public.website_anfragen;
drop policy if exists "website_anfragen_authenticated_insert" on public.website_anfragen;
drop policy if exists "website_anfragen_public_insert" on public.website_anfragen;

create policy "website_anfragen_public_insert"
  on public.website_anfragen for insert
  to anon, authenticated
  with check (true);
