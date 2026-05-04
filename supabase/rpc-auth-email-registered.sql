-- Einmalig im Supabase SQL Editor ausführen (bestehende Projekte), falls schema.sql schon früher ohne diesen Block lief.
-- Danach: Login mit unbekannter E-Mail kann zur Registrierung weiterleiten (siehe Website index.html / mein-abo.html / admin.html).

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
