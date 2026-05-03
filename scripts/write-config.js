'use strict';
/**
 * Erzeugt js/config.js aus Umgebungsvariablen (Cloudflare Pages / CI).
 * Lokal ohne diese Variablen: js/config.js aus js/config.example.js kopieren und anpassen.
 */
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const out = path.join(root, 'js', 'config.js');

const url = (process.env.DAHOAM_SUPABASE_URL || '').trim();
const key = (process.env.DAHOAM_SUPABASE_ANON_KEY || '').trim();
const mail = (process.env.DAHOAM_BAUFPLAN_EMAIL_TO || '').trim();

if (!url || !key) {
  console.error(
    'Fehlende Umgebungsvariablen: DAHOAM_SUPABASE_URL und DAHOAM_SUPABASE_ANON_KEY.\n' +
      '→ Cloudflare Pages: Project → Settings → Environment variables (Production / Preview).\n' +
      '→ Lokal: Kopiere js/config.example.js nach js/config.js und trage Werte ein (ohne npm run build).'
  );
  process.exit(1);
}

const lines = [
  '// Automatisch erzeugt von scripts/write-config.js beim Deploy (npm run build).',
  'window.DAHOAM_SUPABASE_URL = ' + JSON.stringify(url) + ';',
  'window.DAHOAM_SUPABASE_ANON_KEY = ' + JSON.stringify(key) + ';',
];
if (mail) {
  lines.push('window.DAHOAM_BAUFPLAN_EMAIL_TO = ' + JSON.stringify(mail) + ';');
}
lines.push('');

fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, lines.join('\n'), 'utf8');
console.log('OK: geschrieben', path.relative(root, out));
