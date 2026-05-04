-- Demo-Jobs für Kunden-Websites (nach Admin-Arbeit / Agent 2).
-- Voraussetzung: schema.sql + kunden-sites-portal-migration.sql + website_anfragen existieren.
--
-- Ablauf Zielbild:
-- 1) Kunde: Anfrage (website_anfragen) · 2) Admin: „Demo-Job anlegen“ · 3) Du + Cursor-Agent: Repo/Static Site
-- 4) Agent 2: Auth-User + kunden_pakete + kunden_sites (siehe SUPABASE-EINRICHTUNG.md Abschnitt Demo-Jobs)
-- 5) Kunde: kunde-website.html

-- ---------------------------------------------------------------------------
create table if not exists public.kunden_demo_jobs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  website_anfrage_id uuid references public.website_anfragen (id) on delete set null,
  status text not null default 'queued' check (status in (
    'queued',
    'repo_anlegen',
    'cursor_bearbeitung',
    'portal_frei',
    'live',
    'abgebrochen'
  )),
  kunde_email text,
  betrieb_name text,
  payload_snapshot jsonb not null default '{}'::jsonb,
  vorgeschlagenes_repo_slug text,
  github_repo_url text,
  cloudflare_pages_url text,
  agent_brief_md text,
  interne_notizen text
);

create index if not exists kunden_demo_jobs_created_idx on public.kunden_demo_jobs (created_at desc);
create index if not exists kunden_demo_jobs_anfrage_idx on public.kunden_demo_jobs (website_anfrage_id);

alter table public.kunden_demo_jobs enable row level security;

drop policy if exists "kunden_demo_jobs_admin_select" on public.kunden_demo_jobs;
create policy "kunden_demo_jobs_admin_select"
  on public.kunden_demo_jobs for select
  to authenticated
  using (coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin');

drop policy if exists "kunden_demo_jobs_admin_insert" on public.kunden_demo_jobs;
create policy "kunden_demo_jobs_admin_insert"
  on public.kunden_demo_jobs for insert
  to authenticated
  with check (coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin');

drop policy if exists "kunden_demo_jobs_admin_update" on public.kunden_demo_jobs;
create policy "kunden_demo_jobs_admin_update"
  on public.kunden_demo_jobs for update
  to authenticated
  using (coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin')
  with check (coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin');

grant select, insert, update on public.kunden_demo_jobs to authenticated;

-- ---------------------------------------------------------------------------
-- Admin: aus Website-Anfrage einen Demo-Job erzeugen (Payload-Kopie + Repo-Slug-Vorschlag + Agent-Brief)
-- ---------------------------------------------------------------------------
create or replace function public.admin_demo_job_from_anfrage(p_anfrage_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
  p jsonb;
  slug text;
  brief text;
  new_id uuid;
begin
  if p_anfrage_id is null then
    raise exception 'anfrage_id required';
  end if;
  if coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') <> 'admin' then
    raise exception 'forbidden';
  end if;

  select wa.id, wa.payload into r
  from public.website_anfragen wa
  where wa.id = p_anfrage_id;
  if not found then
    raise exception 'anfrage_not_found';
  end if;

  p := coalesce(r.payload, '{}'::jsonb);
  slug := lower(regexp_replace(trim(coalesce(p->>'betrieb_name', 'kunde')), '[^a-zA-Z0-9]+', '-', 'g'));
  slug := trim(both '-' from slug);
  if slug is null or length(slug) < 2 then
    slug := 'kunde';
  end if;
  slug := 'dahoam-' || left(slug, 40);

  insert into public.kunden_demo_jobs (
    website_anfrage_id,
    status,
    kunde_email,
    betrieb_name,
    payload_snapshot,
    vorgeschlagenes_repo_slug
  )
  values (
    p_anfrage_id,
    'queued',
    nullif(trim(p->>'email'), ''),
    nullif(trim(p->>'betrieb_name'), ''),
    p,
    slug
  )
  returning id into new_id;

  brief :=
    E'# Kunden-Demo-Job\n\n' ||
    E'## IDs\n' ||
    E'- **Demo-Job-ID**: `' || new_id::text || E'`\n' ||
    E'- **Website-Anfrage-ID**: `' || p_anfrage_id::text || E'`\n\n' ||
    E'## Vorgeschlagenes GitHub-Repo (Slug)\n' ||
    E'`' || slug || E'`\n\n' ||
    E'## Kunde (aus Anfrage)\n' ||
    E'- E-Mail: ' || coalesce(nullif(trim(p->>'email'), ''), '–') || E'\n' ||
    E'- Betrieb: ' || coalesce(nullif(trim(p->>'betrieb_name'), ''), '–') || E'\n\n' ||
    E'## Deine Aufgaben (Agent „Kunde“)\n' ||
    E'1. **GitHub**: Repo von Template anlegen (`' || slug || E'`), **ohne** Supabase-Keys im öffentlichen Build.\n' ||
    E'2. **Static Site** aus Anfrage/Payload bauen (Texte/Bild-URLs aus Payload; Platzhalter wo nötig).\n' ||
    E'3. **Supabase (nur intern)**: In der **Dahoam-Digital**-Datenbank:\n' ||
    E'   - Auth-User für Kunden-E-Mail anlegen (oder bestehend nutzen),\n' ||
    E'   - `kunden_pakete` (Paket/Preis),\n' ||
    E'   - `kunden_sites` mit `blocks_json` passend zur Demo (eine Zeile pro `user_id`),\n' ||
    E'   - optional `kunden_demo_jobs.status` auf `portal_frei` setzen + `github_repo_url` / `cloudflare_pages_url` eintragen.\n' ||
    E'4. Admin informiert Kunde mit **Zugangsdaten**; Kunde nutzt **kunde-website.html**.\n\n' ||
    E'## Payload (JSON)\n\n```json\n' ||
    trim(both from p::text) ||
    E'\n```\n';

  update public.kunden_demo_jobs
  set agent_brief_md = brief, updated_at = now()
  where id = new_id;

  return new_id;
end;
$$;

revoke all on function public.admin_demo_job_from_anfrage(uuid) from public;
grant execute on function public.admin_demo_job_from_anfrage(uuid) to authenticated;
