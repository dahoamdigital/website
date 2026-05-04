-- In Supabase: SQL → New query → ausführen
--
-- Anschließend:
-- 1) Authentication → Users: Benutzer anlegen (Team + Kunden, jeweils E-Mail + Passwort).
-- 2) Team-Admin: Rolle setzen (sonst kein Zugriff auf admin.html / Aufträge / Editor-Speichern als Admin):
--    Datei supabase/set-admin-role.sql ausführen (E-Mail anpassen) oder im Dashboard unter User → App Metadata role = admin.
-- 3) Project Settings → API: Project URL + anon public key in js/config.js eintragen (wie in js/config.example.js).
-- 4) Website per HTTPS ausliefern (oder lokal testen); gleiche Origin für Cookies.

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

-- Eingeloggtes Team: Auftrag speichern (Editor) – nur wenn app_metadata.role = 'admin'
drop policy if exists "admin_einfgen" on public.bauplan_auftraege;
create policy "admin_einfgen"
  on public.bauplan_auftraege for insert
  to authenticated
  with check (coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin');

drop policy if exists "admin_lesen" on public.bauplan_auftraege;
create policy "admin_lesen"
  on public.bauplan_auftraege for select
  to authenticated
  using (coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin');

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

-- Login-UX: existiert die E-Mail als Auth-User? (ermöglicht Weiterleitung zur Registrierung; geringes Enumeration-Risiko)
create or replace function public.auth_email_registered(p_email text)
returns boolean
language sql
stable
security definer
set search_path = auth
as $$
  select exists (
    select 1
    from auth.users
    where lower(trim(coalesce(p_email, ''))) = lower(email)
  );
$$;

revoke all on function public.auth_email_registered(text) from public;
grant execute on function public.auth_email_registered(text) to anon;
grant execute on function public.auth_email_registered(text) to authenticated;

-- Kontaktformular Startseite (index.html): öffentlich einfügen, nur Team-Admin lesen
create table if not exists public.website_anfragen (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  quelle text not null default 'index_kontakt',
  payload jsonb not null
);

create index if not exists website_anfragen_created_at_idx
  on public.website_anfragen (created_at desc);

alter table public.website_anfragen enable row level security;

grant insert on public.website_anfragen to anon, authenticated;
grant select on public.website_anfragen to authenticated;

drop policy if exists "website_anfragen_anon_insert" on public.website_anfragen;
drop policy if exists "website_anfragen_authenticated_insert" on public.website_anfragen;
drop policy if exists "website_anfragen_public_insert" on public.website_anfragen;
-- Zwei Policies: manche Postgres-/PostgREST-Setups werten „TO anon, authenticated“ anders
create policy "website_anfragen_anon_insert"
  on public.website_anfragen for insert
  to anon
  with check (true);

create policy "website_anfragen_authenticated_insert"
  on public.website_anfragen for insert
  to authenticated
  with check (true);

drop policy if exists "website_anfragen_admin_select" on public.website_anfragen;
create policy "website_anfragen_admin_select"
  on public.website_anfragen for select
  to authenticated
  using (coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin');

-- Direkt .insert().select('id') von anon schlägt an RLS fehl (RETURNING = SELECT ohne Policy).
-- Die Website nutzt stattdessen submit_website_anfrage (SECURITY DEFINER).
create or replace function public.submit_website_anfrage(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
begin
  if p_payload is null then
    raise exception 'payload required';
  end if;
  insert into public.website_anfragen (quelle, payload)
  values ('index_kontakt', p_payload)
  returning id into new_id;
  return new_id;
end;
$$;

revoke all on function public.submit_website_anfrage(jsonb) from public;
grant execute on function public.submit_website_anfrage(jsonb) to anon, authenticated;
