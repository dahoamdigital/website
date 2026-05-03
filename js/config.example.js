// Kopiere diese Datei nach js/config.js und trage deine Werte ein.
// Supabase: Project Settings → API → Project URL + anon public key
//
// Nach dem Live-Deployment (z. B. Cloudflare Pages, Netlify):
//   Supabase → Authentication → URL Configuration
//   → „Site URL“ = deine öffentliche Basis-URL (https://deine-domain.at/)
//   → „Redirect URLs“ = dieselbe URL + ggf. Preview-URLs (*.pages.dev usw.)
// Details: HOSTING.txt im Website-Ordner

window.DAHOAM_SUPABASE_URL = 'https://DEIN-PROJEKT.supabase.co';
window.DAHOAM_SUPABASE_ANON_KEY = 'DEIN-ANON-KEY';

// Optional: Standard-Empfänger für „E-Mail mit Bauplan“ im Editor + Vorschlag im Admin-Login
window.DAHOAM_BAUFPLAN_EMAIL_TO = 'deine@email.at';
