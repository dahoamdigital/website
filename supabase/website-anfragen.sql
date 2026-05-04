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

drop policy if exists "website_anfragen_admin_select" on public.website_anfragen;
create policy "website_anfragen_admin_select"
  on public.website_anfragen for select
  to authenticated
  using (coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin');

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
