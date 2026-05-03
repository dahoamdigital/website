-- In Supabase: SQL → New query → ausführen
--
-- Anschließend:
-- 1) Authentication → Users: Admin-Benutzer anlegen (E-Mail + Passwort) oder „Add user“.
--    Bei „Confirm email“: Nutzer bestätigen, sonst schlägt Login fehl (oder E-Mail-Bestätigung in Auth-Settings deaktivieren nur für Tests).
-- 2) Project Settings → API: Project URL + anon public key in js/config.js eintragen (wie in js/config.example.js).
-- 3) Website per HTTPS ausliefern (oder lokal testen); Editor und admin.html gleiche Origin für Cookies.

create table if not exists public.bauplan_auftraege (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  betrieb text not null,
  ansprechpartner text not null,
  email text not null,
  telefon text,
  region text not null,
  gemeinde text,
  adresse text,
  produkt_wuensche text,
  bemerkungen text,
  editor_nachricht text,
  bauplan_json jsonb not null,
  editor_konto_email text
);

create index if not exists bauplan_auftraege_created_at_idx
  on public.bauplan_auftraege (created_at desc);

alter table public.bauplan_auftraege enable row level security;

drop policy if exists "oeffentlich_einfgen" on public.bauplan_auftraege;
create policy "oeffentlich_einfgen"
  on public.bauplan_auftraege for insert
  to anon
  with check (true);

drop policy if exists "admin_lesen" on public.bauplan_auftraege;
create policy "admin_lesen"
  on public.bauplan_auftraege for select
  to authenticated
  using (true);
