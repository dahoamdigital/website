Edge Function „notify-anfrage“ – E-Mail an Admin nach Kontaktformular
======================================================================

Voraussetzung: Tabelle website_anfragen existiert (supabase/website-anfragen.sql oder schema.sql).

1) Supabase CLI installieren, im Website-Repo einloggen:
   supabase login
   supabase link --project-ref IHRE_PROJECT_REF

2) Secrets setzen:
   supabase secrets set RESEND_API_KEY=re_xxxx
   supabase secrets set NOTIFY_EMAIL=dahoam.digital@gmail.com
   supabase secrets set RESEND_FROM=onboarding@resend.dev
   (RESEND_FROM: nach Domain-Verifizierung in Resend z. B. noreply@ihre-domain.at)

3) Function deployen (JWT nicht prüfen, damit der Aufruf mit anon-Key von der Website klappt):
   supabase functions deploy notify-anfrage --no-verify-jwt

4) Auf Cloudflare Pages (Build-Umgebung) Variable setzen:
   DAHOAM_ANFRAGE_EMAIL_NOTIFY=1
   Danach Deployment neu bauen (npm run build), damit js/config.js die Option enthält.

Ohne Schritt 3–4: Anfragen werden nur in der DB gespeichert; im Admin unter „Website-Anfragen“ sichtbar.

Resend: Ohne eigene Domain oft nur Testversand; NOTIFY_EMAIL ggf. = die bei Resend verifizierte Adresse.
