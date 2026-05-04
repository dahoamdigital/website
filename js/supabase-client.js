/**
 * Gemeinsamer Supabase-Browser-Client und Hilfsfunktion für Team-Admins.
 * Lädt nach @supabase/supabase-js UMD und js/config.js.
 */
(function (global) {
  function getClient() {
    var url = (global.DAHOAM_SUPABASE_URL || '').trim();
    var key = (global.DAHOAM_SUPABASE_ANON_KEY || '').trim();
    if (!url || !key) return null;
    var lib =
      global.supabase && typeof global.supabase.createClient === 'function'
        ? global.supabase
        : typeof supabase !== 'undefined' && supabase && typeof supabase.createClient === 'function'
          ? supabase
          : null;
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

  /** Team-Zugang: in Supabase unter User → raw app metadata → role: "admin" (siehe supabase/set-admin-role.sql). */
  function isAppAdminUser(user) {
    if (!user || !user.app_metadata) return false;
    return user.app_metadata.role === 'admin';
  }

  global.DahoamSupabase = {
    getClient: getClient,
    isAppAdminUser: isAppAdminUser,
  };
})(typeof window !== 'undefined' ? window : this);
