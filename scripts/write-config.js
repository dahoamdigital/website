'use strict';
/**
 * Erzeugt js/config.js aus Umgebungsvariablen (Cloudflare Pages / CI).
 * Lokal ohne diese Variablen: js/config.js aus js/config.example.js kopieren und anpassen (siehe README).
 */
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const out = path.join(root, 'js', 'config.js');

const url = (process.env.DAHOAM_SUPABASE_URL || '').trim();
const key = (process.env.DAHOAM_SUPABASE_ANON_KEY || '').trim();
const mail = (process.env.DAHOAM_BAUFPLAN_EMAIL_TO || '').trim();

// Auf Cloudflare/Netlify ohne gesetzte Variablen: Stub schreiben, damit der Build durchläuft und js/config.js existiert.
const isHostedCi =
  process.env.CF_PAGES === '1' ||
  String(process.env.NETLIFY || '').toLowerCase() === 'true';

if (!url || !key) {
  const msg =
    'Fehlende Umgebungsvariablen: DAHOAM_SUPABASE_URL und DAHOAM_SUPABASE_ANON_KEY.\n' +
    '→ Cloudflare Pages: Workers & Pages → Ihr Projekt → Settings → Environment variables (Production + Preview).\n' +
    '→ Lokal: js/config.example.js nach js/config.js kopieren (ohne npm run build).';
  if (isHostedCi) {
    console.warn('WARN (Build läuft trotzdem): ' + msg);
    const stub = [
      '// Platzhalter: Beim Build fehlten DAHOAM_SUPABASE_URL / DAHOAM_SUPABASE_ANON_KEY. In Cloudflare unter Environment variables eintragen und erneut deployen.',
      'window.DAHOAM_SUPABASE_URL = "";',
      'window.DAHOAM_SUPABASE_ANON_KEY = "";',
    ];
    if (mail) stub.push('window.DAHOAM_BAUFPLAN_EMAIL_TO = ' + JSON.stringify(mail) + ';');
    stub.push('');
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.writeFileSync(out, stub.join('\n'), 'utf8');
    console.log('OK: Stub geschrieben (leere Keys)', path.relative(root, out));
    process.exit(0);
  }
  console.error(msg);
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
