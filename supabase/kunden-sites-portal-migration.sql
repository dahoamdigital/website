-- Kundenportal: eigene Website (Blöcke), Nutzungskontingente, Änderungs-Log, Demo-Zahlungen.
-- Nach schema.sql ausführen (bestehende Projekte: nur diese Datei).
--
-- Hinweis Automatisierung: Spalten github_* und cloudflare_* sind Platzhalter für
-- spätere GitHub-App + Cloudflare Pages API (Edge Function mit Secrets). Keine Live-Calls hier.

-- ---------------------------------------------------------------------------
-- Freikontingente pro Paketcode (muss zu js/pricing.js / kunden_pakete.paket_code passen)
-- ---------------------------------------------------------------------------
create table if not exists public.paket_kontingente (
  paket_code text primary key,
  inkl_bildwechsel_pro_monat int not null default 0,
  inkl_textblock_aenderungen_pro_monat int not null default 0
);

alter table public.paket_kontingente enable row level security;

drop policy if exists "paket_kontingente_lesen" on public.paket_kontingente;
create policy "paket_kontingente_lesen"
  on public.paket_kontingente for select
  to authenticated
  using (true);

grant select on public.paket_kontingente to authenticated;

insert into public.paket_kontingente (paket_code, inkl_bildwechsel_pro_monat, inkl_textblock_aenderungen_pro_monat)
values
  ('starter', 0, 0),
  ('standard', 3, 2),
  ('premium', 10, 5)
on conflict (paket_code) do update set
  inkl_bildwechsel_pro_monat = excluded.inkl_bildwechsel_pro_monat,
  inkl_textblock_aenderungen_pro_monat = excluded.inkl_textblock_aenderungen_pro_monat;

-- ---------------------------------------------------------------------------
-- Kundenseite (ein Datensatz pro Kunde im MVP)
-- ---------------------------------------------------------------------------
create table if not exists public.kunden_sites (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  user_id uuid not null references auth.users (id) on delete cascade,
  anzeige_name text,
  slug text,
  status text not null default 'entwurf' check (status in ('entwurf', 'provisionierung', 'live', 'fehler')),
  live_url text,
  preview_url text,
  github_repo_owner text,
  github_repo_name text,
  github_default_branch text default 'main',
  cloudflare_account_id text,
  cloudflare_pages_project text,
  blocks_json jsonb not null default '{}'::jsonb,
  published_blocks_json jsonb,
  constraint kunden_sites_user_id_key unique (user_id)
);

create index if not exists kunden_sites_user_id_idx on public.kunden_sites (user_id);

alter table public.kunden_sites enable row level security;

drop policy if exists "kunden_sites_eigenes_select" on public.kunden_sites;
create policy "kunden_sites_eigenes_select"
  on public.kunden_sites for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "kunden_sites_eigenes_insert" on public.kunden_sites;
create policy "kunden_sites_eigenes_insert"
  on public.kunden_sites for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "kunden_sites_eigenes_update" on public.kunden_sites;
create policy "kunden_sites_eigenes_update"
  on public.kunden_sites for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "kunden_sites_admin_select" on public.kunden_sites;
create policy "kunden_sites_admin_select"
  on public.kunden_sites for select
  to authenticated
  using (coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin');

grant select, insert, update on public.kunden_sites to authenticated;

-- ---------------------------------------------------------------------------
-- Änderungs-Log (für Kontingente & spätere Abrechnung)
-- ---------------------------------------------------------------------------
create table if not exists public.site_aenderungen_log (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  user_id uuid not null references auth.users (id) on delete cascade,
  site_id uuid references public.kunden_sites (id) on delete set null,
  typ text not null check (typ in ('bild', 'text')),
  war_gratis boolean not null default false,
  meta jsonb not null default '{}'::jsonb
);

-- Kein Index auf date_trunc(month, timestamptz): in PG nicht IMMUTABLE → 42P17.
-- Stattdessen (user_id, created_at): reicht für „diesen Monat“-Filter in den RPCs.
create index if not exists site_aenderungen_log_user_created_idx
  on public.site_aenderungen_log (user_id, created_at desc);

alter table public.site_aenderungen_log enable row level security;

drop policy if exists "site_aenderungen_eigenes_select" on public.site_aenderungen_log;
create policy "site_aenderungen_eigenes_select"
  on public.site_aenderungen_log for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "site_aenderungen_admin_select" on public.site_aenderungen_log;
create policy "site_aenderungen_admin_select"
  on public.site_aenderungen_log for select
  to authenticated
  using (coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin');

grant select on public.site_aenderungen_log to authenticated;

-- Inserts nur über RPC (SECURITY DEFINER), damit Kontingente nicht umgangen werden können.
revoke insert on public.site_aenderungen_log from authenticated;

-- ---------------------------------------------------------------------------
-- Demo-Zahlungen (kein PSP; nur Buchungsnachweis für UI-Tests)
-- ---------------------------------------------------------------------------
create table if not exists public.demo_zahlungen (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  user_id uuid not null references auth.users (id) on delete cascade,
  betrag_cent int not null check (betrag_cent > 0 and betrag_cent <= 500000),
  zweck text not null default 'Demo',
  status text not null default 'demo_abgeschlossen' check (status in ('demo_abgeschlossen', 'demo_storniert')),
  referenz text
);

create index if not exists demo_zahlungen_user_idx on public.demo_zahlungen (user_id, created_at desc);

alter table public.demo_zahlungen enable row level security;

drop policy if exists "demo_zahlungen_eigenes_select" on public.demo_zahlungen;
create policy "demo_zahlungen_eigenes_select"
  on public.demo_zahlungen for select
  to authenticated
  using (auth.uid() = user_id);

grant select on public.demo_zahlungen to authenticated;

revoke insert on public.demo_zahlungen from authenticated;

-- ---------------------------------------------------------------------------
-- RPC: Kontingente-Anzeige
-- ---------------------------------------------------------------------------
create or replace function public.kunde_portal_kontingente()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  p_code text;
  lim_b int;
  lim_t int;
  used_b int;
  used_t int;
  mon_start timestamptz := date_trunc('month', timezone('utc', now()));
  mon_end timestamptz := mon_start + interval '1 month';
begin
  if uid is null then
    return null;
  end if;
  select kp.paket_code into p_code
  from public.kunden_pakete kp
  where kp.user_id = uid
  limit 1;
  if p_code is null then
    return jsonb_build_object('error', 'kein_abo');
  end if;
  select pk.inkl_bildwechsel_pro_monat, pk.inkl_textblock_aenderungen_pro_monat
  into lim_b, lim_t
  from public.paket_kontingente pk
  where pk.paket_code = p_code;
  lim_b := coalesce(lim_b, 0);
  lim_t := coalesce(lim_t, 0);
  select
    count(*) filter (where l.typ = 'bild' and l.war_gratis),
    count(*) filter (where l.typ = 'text' and l.war_gratis)
  into used_b, used_t
  from public.site_aenderungen_log l
  where l.user_id = uid
    and l.created_at >= mon_start
    and l.created_at < mon_end;
  used_b := coalesce(used_b, 0);
  used_t := coalesce(used_t, 0);
  return jsonb_build_object(
    'paket_code', p_code,
    'limit_bild_gratis', lim_b,
    'limit_text_gratis', lim_t,
    'verbrauch_bild_gratis', used_b,
    'verbrauch_text_gratis', used_t,
    'rest_bild_gratis', greatest(lim_b - used_b, 0),
    'rest_text_gratis', greatest(lim_t - used_t, 0)
  );
end;
$$;

revoke all on function public.kunde_portal_kontingente() from public;
grant execute on function public.kunde_portal_kontingente() to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: Änderungen verbuchen (Bild- / Text-Einheiten; schreibt Log)
-- ---------------------------------------------------------------------------
create or replace function public.kunde_site_aenderungen_buchen(p_bild int, p_text int, p_site_id uuid default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  p_code text;
  lim_b int;
  lim_t int;
  used_b int;
  used_t int;
  mon_start timestamptz := date_trunc('month', timezone('utc', now()));
  mon_end timestamptz := mon_start + interval '1 month';
  i int;
  rest_b int;
  rest_t int;
  bild_bezahlt int := 0;
  text_bezahlt int := 0;
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;
  if p_bild < 0 or p_text < 0 or p_bild > 25 or p_text > 25 then
    raise exception 'invalid counts';
  end if;

  select kp.paket_code into p_code from public.kunden_pakete kp where kp.user_id = uid limit 1;
  if p_code is null then
    raise exception 'kein_abo';
  end if;

  select pk.inkl_bildwechsel_pro_monat, pk.inkl_textblock_aenderungen_pro_monat
  into lim_b, lim_t
  from public.paket_kontingente pk
  where pk.paket_code = p_code;
  lim_b := coalesce(lim_b, 0);
  lim_t := coalesce(lim_t, 0);

  select
    count(*) filter (where l.typ = 'bild' and l.war_gratis),
    count(*) filter (where l.typ = 'text' and l.war_gratis)
  into used_b, used_t
  from public.site_aenderungen_log l
  where l.user_id = uid
    and l.created_at >= mon_start
    and l.created_at < mon_end;
  used_b := coalesce(used_b, 0);
  used_t := coalesce(used_t, 0);

  rest_b := greatest(lim_b - used_b, 0);
  rest_t := greatest(lim_t - used_t, 0);

  for i in 1..p_bild loop
    if rest_b > 0 then
      insert into public.site_aenderungen_log (user_id, site_id, typ, war_gratis, meta)
      values (uid, p_site_id, 'bild', true, '{}'::jsonb);
      rest_b := rest_b - 1;
    else
      insert into public.site_aenderungen_log (user_id, site_id, typ, war_gratis, meta)
      values (uid, p_site_id, 'bild', false, jsonb_build_object('hinweis', 'ausserhalb_kontingent'));
      bild_bezahlt := bild_bezahlt + 1;
    end if;
  end loop;

  for i in 1..p_text loop
    if rest_t > 0 then
      insert into public.site_aenderungen_log (user_id, site_id, typ, war_gratis, meta)
      values (uid, p_site_id, 'text', true, '{}'::jsonb);
      rest_t := rest_t - 1;
    else
      insert into public.site_aenderungen_log (user_id, site_id, typ, war_gratis, meta)
      values (uid, p_site_id, 'text', false, jsonb_build_object('hinweis', 'ausserhalb_kontingent'));
      text_bezahlt := text_bezahlt + 1;
    end if;
  end loop;

  return jsonb_build_object(
    'bild_gratis_gebucht', p_bild - bild_bezahlt,
    'bild_zusaetzlich_bezahlt', bild_bezahlt,
    'text_gratis_gebucht', p_text - text_bezahlt,
    'text_zusaetzlich_bezahlt', text_bezahlt
  );
end;
$$;

revoke all on function public.kunde_site_aenderungen_buchen(int, int, uuid) from public;
grant execute on function public.kunde_site_aenderungen_buchen(int, int, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: Demo-Zahlung (nur Datenbankeintrag)
-- ---------------------------------------------------------------------------
create or replace function public.demo_zahlung_anlegen(p_cent int, p_zweck text default 'Demo')
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  new_id uuid;
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;
  if p_cent is null or p_cent < 1 or p_cent > 500000 then
    raise exception 'invalid amount';
  end if;
  insert into public.demo_zahlungen (user_id, betrag_cent, zweck, status, referenz)
  values (uid, p_cent, coalesce(nullif(trim(p_zweck), ''), 'Demo'), 'demo_abgeschlossen', 'demo-' || gen_random_uuid()::text)
  returning id into new_id;
  return new_id;
end;
$$;

revoke all on function public.demo_zahlung_anlegen(int, text) from public;
grant execute on function public.demo_zahlung_anlegen(int, text) to authenticated;
