// Kopieren Sie diese Datei nach js/config.js und tragen Sie Ihre Werte ein.
// Supabase: Project Settings → API → Project URL + anon public key
//
// WICHTIG: DAHOAM_SUPABASE_URL = nur die Project URL, z. B. https://abcdefgh.supabase.co
//          (ohne /rest/v1/ — der Client ergänzt die Pfade selbst.)
//
// Nach dem Live-Deployment (z. B. Cloudflare Pages, Netlify):
//   Supabase → Authentication → URL Configuration
//   → „Site URL“ = Ihre öffentliche Basis-URL (https://ihre-domain.at/)
//   → „Redirect URLs“ = dieselbe URL + ggf. Preview-URLs (*.pages.dev usw.) + passwort-neu.html
// Details: HOSTING.txt und SUPABASE-EINRICHTUNG.md im Website-Ordner

window.DAHOAM_SUPABASE_URL = 'https://bridnaylbfsaahokghua.supabase.co';
window.DAHOAM_SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJyaWRuYXlsYmZzYWFob2tnaHVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4NTM2MjgsImV4cCI6MjA5MzQyOTYyOH0.glc23qfi1-BhLm25YI1NnwBPqJZ4nMqHOI2j5F8vXAQ';

// Optional: Standard-Empfänger für „E-Mail mit Bauplan“ im Editor + Vorschlag im Admin-Login
window.DAHOAM_BAUFPLAN_EMAIL_TO = 'ihre@email.at';

// Optional: feste öffentliche Basis-URL (https://www.ihre-domain.at) – nur in Sonderfällen
// window.DAHOAM_SITE_ORIGIN = 'https://www.ihre-domain.at';
