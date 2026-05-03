# Dahoam-Digital – Website

Statische Website (HTML/CSS/JS) mit optionalem Supabase-Login.

## Erste Schritte (lokal)

1. `js/config.example.js` nach `js/config.js` kopieren und URL + anon-Key eintragen.
2. `index.html` im Browser öffnen (oder „Live Server“ in VS Code).

Ohne `js/config.js` fehlen Supabase-URL und Key – Login und Editor-Absenden funktionieren dann nicht.

## So arbeitest du ohne Upload (Git + Cloudflare)

Sobald **GitHub** mit **Cloudflare Pages** verbunden ist, musst du **nichts mehr zu Cloudflare hochladen**.

1. Du änderst Dateien **im Repository** (lokal in Cursor/VS Code **oder** direkt auf github.com).
2. Du speicherst die Änderung mit **Git: commit + push** nach `main`.
3. **Cloudflare** startet automatisch einen neuen Build und veröffentlicht die Seite.

**Hinweis:** `js/config.js` mit den Keys liegt **nicht** im Repo (`.gitignore`). Die **Live-Site** bekommt die Werte bei jedem Deploy aus den **Cloudflare-Umgebungsvariablen** (`npm run build` → `scripts/write-config.js`).

### Cloudflare Pages (Build)

- **Framework preset:** None  
- **Build command:** `npm run build`  
- **Build output directory:** `/`  
- **Environment variables:** `DAHOAM_SUPABASE_URL`, `DAHOAM_SUPABASE_ANON_KEY`, optional `DAHOAM_BAUFPLAN_EMAIL_TO`.

Weitere Infos: **HOSTING.txt**.

## Dateien für Hosting

| Datei | Rolle |
|--------|--------|
| `_headers` | HTTP-Header (Cloudflare Pages, Netlify) |
| `vercel.json` | Header für Vercel |
| `netlify.toml` | Netlify Publish-Root |
| `.htaccess` | nur Apache (z. B. InfinityFree) |
