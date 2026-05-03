// Wird vor js/config.js geladen. Falls config.js fehlt (kein Build) oder leer ist, bleiben die Werte leer.
(function () {
  if (typeof window.DAHOAM_SUPABASE_URL === 'undefined') window.DAHOAM_SUPABASE_URL = '';
  if (typeof window.DAHOAM_SUPABASE_ANON_KEY === 'undefined') window.DAHOAM_SUPABASE_ANON_KEY = '';
  if (typeof window.DAHOAM_SITE_ORIGIN === 'undefined') window.DAHOAM_SITE_ORIGIN = '';
})();
