-- Team-Admin: Rolle in den JWT / app_metadata setzen (nur für ausgewählte Logins).
-- Im Supabase-Dashboard: SQL → New query → E-Mail anpassen → Run.
--
-- Danach neu einloggen (oder Token ablaufen lassen), damit der JWT die Rolle enthält.

update auth.users
set raw_app_meta_data =
  coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', 'admin')
where lower(email) = lower('team@ihre-domain.at');

-- Prüfen:
-- select id, email, raw_app_meta_data from auth.users where lower(email) = lower('team@ihre-domain.at');
