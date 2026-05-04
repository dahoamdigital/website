-- Einmalig ausführen, falls schema.sql schon ohne diesen Block lief.

create table if not exists public.website_anfragen (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  quelle text not null default 'index_kontakt',
  payload jsonb not null
);

create index if not exists website_anfragen_created_at_idx
  on public.website_anfragen (created_at desc);

alter table public.website_anfragen enable row level security;

drop policy if exists "website_anfragen_anon_insert" on public.website_anfragen;
drop policy if exists "website_anfragen_authenticated_insert" on public.website_anfragen;
drop policy if exists "website_anfragen_public_insert" on public.website_anfragen;
create policy "website_anfragen_public_insert"
  on public.website_anfragen for insert
  to anon, authenticated
  with check (true);

drop policy if exists "website_anfragen_admin_select" on public.website_anfragen;
create policy "website_anfragen_admin_select"
  on public.website_anfragen for select
  to authenticated
  using (coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin');
