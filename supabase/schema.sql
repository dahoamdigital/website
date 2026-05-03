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

-- Kunden-Abo (mein-abo.html): eine Zeile pro Auth-User.
-- Zeilen legen Sie in Supabase SQL (als postgres) oder mit service_role an – nicht öffentlich per insert.
create table if not exists public.kunden_pakete (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  user_id uuid not null references auth.users (id) on delete cascade,
  paket_code text not null,
  paket_name text not null,
  monatspreis numeric(10, 2) not null,
  status text not null default 'aktiv' check (status in ('aktiv', 'gekuendigt', 'pausiert')),
  vertragsbeginn date,
  gekuendigt_zum date,
  constraint kunden_pakete_user_id_key unique (user_id)
);

create index if not exists kunden_pakete_user_id_idx on public.kunden_pakete (user_id);

alter table public.kunden_pakete enable row level security;

drop policy if exists "kunde_liest_eigenes_paket" on public.kunden_pakete;
create policy "kunde_liest_eigenes_paket"
  on public.kunden_pakete for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "kunde_updated_eigenes_paket" on public.kunden_pakete;
create policy "kunde_updated_eigenes_paket"
  on public.kunden_pakete for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
