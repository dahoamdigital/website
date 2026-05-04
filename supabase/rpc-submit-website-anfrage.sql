-- Einmal im SQL Editor ausführen, wenn das Kontaktformular trotz INSERT-Policies
-- „new row violates row-level security“ meldet (Ursache: .insert().select() braucht SELECT-RLS).

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
