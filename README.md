# Dahoam-Digital – Website

Statische Website (HTML/CSS/JS) mit optionalem Supabase-Login.

**Supabase Schritt für Schritt:** siehe **[SUPABASE-EINRICHTUNG.md](./SUPABASE-EINRICHTUNG.md)** (Projekt, Keys, SQL, Auth-URLs, **Team-Admin-Rolle**, Kundenkonto „Mein Abo“, Passwort-Reset).

Gemeinsamer Browser-Code: **`js/supabase-client.js`** (wird nach `config.js` und der Supabase-UMD-Bibliothek eingebunden) – erzeugt den Client und prüft `app_metadata.role === 'admin'`.

## Erste Schritte (lokal)

1. `js/config.example.js` nach `js/config.js` kopieren und URL sowie anon-Key eintragen.
2. `index.html` im Browser öffnen (oder „Live Server“ in VS Code).

Ohne `js/config.js` fehlen Supabase-URL und Key – Login und Editor-Absenden funktionieren dann nicht.

## So arbeiten Sie ohne Upload (Git + Cloudflare)

Sobald **GitHub** mit **Cloudflare Pages** verbunden ist, müssen Sie **nichts mehr zu Cloudflare hochladen**.

1. Sie ändern Dateien **im Repository** (lokal in Cursor/VS Code **oder** direkt auf github.com).
2. Sie speichern die Änderung mit **Git: commit** nach `main` (der **Push** kann automatisch laufen, siehe unten).
3. **Cloudflare** startet automatisch einen neuen Build und veröffentlicht die Seite.

### Auto-Push nach jedem Commit (lokal)

Einmal im Website-Ordner ausführen:

```bash
git config core.hooksPath .githooks
```

Danach führt Git nach jedem erfolgreichen **`git commit`** automatisch **`git push`** auf den aktuellen Branch aus (Skript `.githooks/post-commit`). In Cursor sorgt die Projektregel dafür, dass der Agent nach inhaltlichen Änderungen committet und pusht.

**Hinweis:** `js/config.js` mit den Keys liegt **nicht** im Repo (`.gitignore`). Die **Live-Site** erhält die Werte bei jedem Deploy aus den **Cloudflare-Umgebungsvariablen** (`npm run build` → `scripts/write-config.js`).

### Cloudflare Pages (Build)

- **Framework preset:** None  
- **Build command:** `npm run build`  
- **Build output directory:** `/`  
- **Environment variables:** `DAHOAM_SUPABASE_URL`, `DAHOAM_SUPABASE_ANON_KEY`, optional `DAHOAM_BAUFPLAN_EMAIL_TO`, optional `DAHOAM_SITE_ORIGIN` (feste öffentliche Basis-URL für erzeugte `js/config.js`).

Weitere Infos: **HOSTING.txt**.

### Login auf der Live-Seite: „Kein Supabase-Client“ / URL oder Key fehlen

Die **anon**-Credentials kommen auf Cloudflare nur aus dem **Build**, nicht aus Git.

1. Cloudflare → **Workers & Pages** → Ihr Projekt → **Settings** → **Environment variables**.
2. Für **Production** (und bei Bedarf **Preview**) anlegen:
   - `DAHOAM_SUPABASE_URL` = Supabase Project URL (z. B. `https://xxxx.supabase.co`)
   - `DAHOAM_SUPABASE_ANON_KEY` = **anon public** key (Dashboard → Project Settings → API – **nicht** der `service_role`-Key)
3. **Save** → Tab **Deployments** → letztes Deployment **Retry deployment** (oder einen neuen Commit pushen).

Ohne diese Variablen erzeugt der Build eine leere `js/config.js` – die Seite lädt, **Anmelden** funktioniert erst nach korrektem Deploy mit Werten.

## Dateien für Hosting

| Datei | Rolle |
|--------|--------|
| `_headers` | HTTP-Header (Cloudflare Pages, Netlify) |
| `vercel.json` | Header für Vercel |
| `netlify.toml` | Netlify Publish-Root |
| `.htaccess` | nur Apache (z. B. InfinityFree) |
| `SUPABASE-EINRICHTUNG.md` | Schritt-für-Schritt: Supabase-Projekt, Keys, SQL, Auth-URLs, Team-Admin, Kunden |
| `js/supabase-client.js` | Gemeinsamer Supabase-Client + Prüfung `isAppAdminUser` (nach UMD + `config.js`) |
| `passwort-neu.html` | Passwort-Reset (Redirect-Ziel für Supabase Auth) |

## Kundenportal „Mein Abo“

Die Seite **mein-abo.html** liest das aktuelle Paket aus der Supabase-Tabelle **`kunden_pakete`** (siehe `supabase/schema.sql`). Nach dem SQL-Deploy:

1. Legen Sie in **Authentication** einen Benutzer für die Kundin / den Kunden an (oder lassen Sie sich selbst registrieren, falls Sie Sign-up nutzen).
2. Fügen Sie **eine Zeile** in `kunden_pakete` ein (`user_id` = UUID des Auth-Nutzers, `paket_code`, `paket_name`, `monatspreis`, optional `vertragsbeginn`). Das geht in der SQL-Konsole als postgres oder mit dem **service_role**-Key – nicht mit dem anon-Key aus dem Browser.

Kundinnen und Kunden können eingeloggt nur **lesen** und den Status per **Kündigen** auf `gekuendigt` setzen (kein öffentliches `INSERT` für diese Tabelle).
