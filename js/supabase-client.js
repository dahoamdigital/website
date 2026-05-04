/**
 * Gemeinsamer Supabase-Browser-Client und Hilfsfunktion für Team-Admins.
 * Lädt nach @supabase/supabase-js UMD und js/config.js.
 */
(function (global) {
  function getLib() {
    if (global.supabase && typeof global.supabase.createClient === 'function') return global.supabase;
    if (typeof supabase !== 'undefined' && supabase && typeof supabase.createClient === 'function') return supabase;
    return null;
  }

  function getClient() {
    var url = (global.DAHOAM_SUPABASE_URL || '').trim();
    var key = (global.DAHOAM_SUPABASE_ANON_KEY || '').trim();
    if (!url || !key) return null;
    var lib = getLib();
    if (!lib) return null;
    return lib.createClient(url, key, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
        storage: global.localStorage,
      },
    });
  }

  /** True wenn URL/Key fehlen oder nur Platzhalter aus dem Build. */
  function isSupabaseEnvMissing() {
    var url = (global.DAHOAM_SUPABASE_URL || '').trim();
    var key = (global.DAHOAM_SUPABASE_ANON_KEY || '').trim();
    return !url || !key || global.__DAHOAM_BUILD_STUB__ === true;
  }

  /**
   * Deutscher Hinweis, wenn kein Client möglich ist (falsche Meldung „nicht erreichbar“ vermeiden:
   * meist fehlt die gebaute js/config.js / Cloudflare-Build, nicht das Supabase-Rechenzentrum).
   */
  function explainWhyNoClient() {
    var url = (global.DAHOAM_SUPABASE_URL || '').trim();
    var key = (global.DAHOAM_SUPABASE_ANON_KEY || '').trim();
    if (!url || !key || global.__DAHOAM_BUILD_STUB__ === true) {
      return (
        'Auf dieser Seite fehlt die Supabase-Konfiguration (das ist kein „Server down“). ' +
        'Typisch: In Cloudflare Pages unter Environment variables (Production) müssen exakt DAHOAM_SUPABASE_URL und DAHOAM_SUPABASE_ANON_KEY stehen; Build command = npm run build; Build output = /; danach Retry deployment. ' +
        'Prüfen: Im Browser die Adresse …/js/config.js öffnen – wenn URL/Key leer oder __DAHOAM_BUILD_STUB__ = true, hat der Build die Werte nicht übernommen. URL nur bis .supabase.co, ohne /rest/v1/.'
      );
    }
    if (!getLib()) {
      return 'Die Supabase-Bibliothek (supabase-js) wurde nicht geladen. Bitte Seite neu laden, Adblocker testweise aus, oder prüfen, ob Skripte blockiert werden.';
    }
    return '';
  }

  /** Team-Zugang: in Supabase unter User → raw app metadata → role: "admin" (siehe supabase/set-admin-role.sql). */
  function isAppAdminUser(user) {
    if (!user || !user.app_metadata) return false;
    return user.app_metadata.role === 'admin';
  }

  global.DahoamSupabase = {
    getClient: getClient,
    isAppAdminUser: isAppAdminUser,
    isSupabaseEnvMissing: isSupabaseEnvMissing,
    explainWhyNoClient: explainWhyNoClient,
  };
})(typeof window !== 'undefined' ? window : this);
