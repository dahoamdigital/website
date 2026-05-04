# Supabase einrichten – Schritt für Schritt

Damit **Anmelden** (Startseite, Team), **Admin**, **Mein Abo** (Kunden) und **Passwort zurücksetzen** funktionieren, brauchen Sie ein Supabase-Projekt, die **anon**-Keys in der Website und passende **Auth-URLs**. Arbeiten Sie die Schritte der Reihe nach ab.

**Bestehendes Projekt (Upgrade):** Wenn `schema.sql` schon einmal lief, führen Sie die **aktuellen** `drop policy` / `create policy`-Blöcke für `bauplan_auftraege` aus `supabase/schema.sql` erneut aus und setzen Sie die **Admin-Rolle** (Schritt 8b), sonst können Team-Konten keine Aufträge mehr lesen oder speichern.

---

## 0) Nur Live (Cloudflare Pages) – Login ohne lokale `config.js`

Hier steht **nicht** „ein Link in die Website schreiben“. Die Website lädt beim **Build** auf Cloudflare eine **`js/config.js`**, die aus **Umgebungsvariablen** gefüllt wird. Sie tragen also in **Cloudflare** zwei **Namen** (`DAHOAM_SUPABASE_URL` und `DAHOAM_SUPABASE_ANON_KEY`) ein und als **Wert** jeweils das, was Sie in **Supabase** kopieren.

---

### A) Werte in Supabase finden und kopieren (nur lesen)

1. Browser öffnen und bei **[supabase.com](https://supabase.com)** anmelden.
2. Ihr **Projekt** auswählen (Dashboard des Projekts).
3. Ganz links in der **Seitenleiste** nach unten scrollen → auf das **Zahnrad** **Project Settings** klicken.
4. Im Untermenü von Project Settings den Punkt **API** anklicken.
5. **Project URL**  
   - Dort steht **ein** Textfeld / eine URL, z. B. `https://abcdefghijklmnop.supabase.co`.  
   - **Genau diese Zeichenkette** kopieren (Button „Copy“ oder markieren und Strg+C).  
   - **Wichtig:** Das ist **nicht** die lange REST-Adresse mit `/rest/v1/` am Ende. Wenn irgendwo `/rest/v1/` dransteht, **nicht** verwenden – nur die kurze **Project URL** bis `.supabase.co`.
6. **anon public**-Key  
   - Auf derselben **API**-Seite weiter nach unten zu **Project API keys**.  
   - Bei **anon** / **public** (nicht bei **service_role**!) auf **Reveal** / **Anzeigen** klicken und den **langen** Schlüssel kopieren (beginnt oft mit `eyJ…`).  
   - Den **service_role**-Key **niemals** in Cloudflare oder ins Repo packen – nur **anon public**.

**Merke:** Sie kopieren aus Supabase **zwei getrennte Dinge**: (1) die **URL** und (2) den **anon**-Key. Beides kommt später in Cloudflare – aber unter **zwei verschiedenen Namen** (siehe Teil B).

---

### B) In Cloudflare Pages eintragen (Variable **Name** + **Value**)

1. Browser: **[dash.cloudflare.com](https://dash.cloudflare.com)** → anmelden.
2. Linkes Menü: **Workers & Pages** anklicken.
3. Oben den Bereich **Workers & Pages** / **Overview** – dort Ihr **Pages**-Projekt auswählen (der Name, der zu Ihrer Website/GitHub-Repo gehört, **nicht** „Workers“ aus Versehen).
4. Im Projekt oben die Registerkarte **Settings** öffnen.
5. In der linken Spalte unter Settings: **Variables and Secrets** wählen (bei älterer Oberfläche kann der Punkt **Environment variables** heißen – gleicher Zweck).
6. Wenn es **Production** und **Preview** getrennt gibt: zuerst **Production** auswählen (das ist Ihre Live-Website).
7. **Erste Variable anlegen**  
   - Button z. B. **Add** / **Add variable** / **Edit variables**.  
   - **Name** (exakt so, Großbuchstaben und Unterstriche): `DAHOAM_SUPABASE_URL`  
   - **Value** (Wert): die **Project URL** aus Supabase **einfügen** (Strg+V), z. B. `https://ihr-projekt.supabase.co` — wieder: **ohne** `/rest/v1/`.  
   - Speichern / hinzufügen.
8. **Zweite Variable anlegen**  
   - **Name:** `DAHOAM_SUPABASE_ANON_KEY`  
   - **Value:** den kopierten **anon public**-Key einfügen.  
   - Optional können Sie diesen Wert als **Secret** / verschlüsselt speichern, wenn Cloudflare das anbietet – funktional egal, Hauptsache der Key steht unter **diesem** Namen.
9. **Optional:** weitere Variable **Name:** `DAHOAM_BAUFPLAN_EMAIL_TO` — **Value:** Ihre E-Mail (nur für Vorbefüllung im Login/Editor).

---

### C) Neu bauen (damit die Live-Seite die Werte wirklich nutzt)

1. Im selben Cloudflare-Projekt den Tab **Deployments** öffnen.
2. Beim **letzten** Deployment **⋯** (Menü) → **Retry deployment** wählen **oder** einen neuen Commit auf `main` pushen.  
   Beim Build läuft `npm run build` → **`scripts/write-config.js`** schreibt aus den Variablen die ausgelieferte **`js/config.js`** (die Datei liegt **nicht** im Git, existiert aber auf der gebauten Website).

**Erfolg prüfen:** Ihre **öffentliche** Website-URL im Browser öffnen → z. B. `/admin.html` oder Startseite **Anmelden** → es darf **nicht** mehr „Supabase nicht konfiguriert“ / „URL oder Key fehlen“ erscheinen. (Falsches Passwort ist dann schon ein „gutes“ Zeichen: Supabase wird erreicht.)

**Ohne Teil B + C** bleibt die `js/config.js` auf dem Server leer → Login geht nicht.

---

### D) Variablen in Cloudflare stehen, trotzdem Fehlermeldung „nicht konfiguriert“

**Häufigste Ursache:** Im Cloudflare-Projekt ist **kein Build command** eingetragen (Feld leer). Dann läuft `npm run build` nie → **`js/config.js`** wird nicht geschrieben.

**Wo eintragen (Kurz):** **Workers & Pages** → Ihr **Pages**-Projekt → **Settings** → links **Build** / **Builds** / **Builds & deployments** → Build-Konfiguration bearbeiten.  
**Ausführlicher Klickpfad:** siehe **`HOSTING.txt`** ganz oben (Block „BUILD COMMAND FEHLT?“).

1. Dort eintragen:
   - **Build command:** exakt `npm run build`
   - **Build output directory:** `/` (ein Schrägstrich = Root des Repos, dort liegt `index.html`)
2. **Warum:** `js/config.js` liegt **nicht** im Git (`.gitignore`). Nur der Build führt `scripts/write-config.js` aus und **schreibt** `js/config.js` mit Ihren Umgebungsvariablen. Ohne `npm run build` bleibt die Seite ohne gültige Keys.
3. **Prüfen:** Im Browser `https://Ihre-Live-Domain/js/config.js` öffnen. Steht dort `__DAHOAM_BUILD_STUB__ = true` oder sind URL/Key leer, hat der Build die Variablen **nicht** gesehen → Namen exakt `DAHOAM_SUPABASE_URL` und `DAHOAM_SUPABASE_ANON_KEY`, Umgebung **Production**, danach erneut **Retry deployment**.
4. In den **Build logs** (Deployments → Build-Log) nach `WARN` oder `OK: geschrieben js/config.js` suchen.

**Konto anlegen (Registrierung):** Seite **`konto-anlegen.html`** – in Supabase **Authentication** → **Providers** → **Email** muss die **Registrierung** erlaubt sein („Confirm email“ / Sign-ups je nach Projekt). **Redirect URLs** müssen Ihre Live-Domain und **`…/mein-abo.html`** abdecken (siehe Abschnitt 7).

Danach mindestens noch: **Abschnitt 5** (SQL), **7** (Auth-URLs zur Live-Domain), **8** (Benutzer + Admin-Rolle für Team), bei Kunden **9** (`kunden_pakete`).

---

## 1) Supabase-Projekt anlegen

1. Öffnen Sie [supabase.com](https://supabase.com) und melden sich an.
2. **New project** → Organisation wählen → **Name**, **Datenbank-Passwort**, **Region** (z. B. Frankfurt) → **Create new project**.
3. Warten Sie, bis das Projekt **„Active“** ist (ein bis zwei Minuten).

---

## 2) API-URL und anon-Key holen

1. Im linken Menü: **Project Settings** (Zahnrad) → **API**.
2. Notieren Sie:
   - **Project URL** (z. B. `https://abcdefgh.supabase.co`)
   - **anon public** unter *Project API keys* (langer String, beginnt oft mit `eyJ…`).

**Wichtig:** Verwenden Sie nur den **anon public**-Key im Browser / in Cloudflare. Den **service_role**-Key niemals in die Website legen.

---

## 3) Keys lokal eintragen (optional – nur wenn Sie am PC ohne Cloudflare testen)

1. Im Ordner `website/js`: Datei **`config.example.js`** nach **`config.js`** kopieren.
2. In **`config.js`** eintragen:
   - `window.DAHOAM_SUPABASE_URL` = Ihre **Project URL** (z. B. `https://xxxx.supabase.co`) – **ohne** `/rest/v1/` am Ende, sonst schlägt der Login fehl.  
   - `window.DAHOAM_SUPABASE_ANON_KEY` = Ihr anon-Key  
3. Optional: `window.DAHOAM_BAUFPLAN_EMAIL_TO` = Ihre E-Mail (Vorbefüllung im Login).
4. Optional: Wenn Ihre **öffentliche** Website-URL von der Adresse abweicht, unter der Sie testen (selten):  
   `window.DAHOAM_SITE_ORIGIN = 'https://www.ihre-domain.at';`  
   Sonst wird für Passwort-Reset automatisch `window.location.origin` verwendet.

`config.js` liegt in **`.gitignore`** und wird nicht ins Git hochgeladen.

---

## 4) Keys auf Cloudflare Pages (Live-Seite)

**Ausführlich Schritt für Schritt:** siehe **Abschnitt 0** oben (Teil A = Supabase kopieren, Teil B = Cloudflare einfügen, Teil C = Retry deployment).

Kurz die **Namen** und **Werte**:

| Variable in Cloudflare (Name) | Woher der Wert (Supabase) |
|--------------------------------|---------------------------|
| `DAHOAM_SUPABASE_URL` | **Project Settings → API → Project URL** (`https://….supabase.co`, **ohne** `/rest/v1/`) |
| `DAHOAM_SUPABASE_ANON_KEY` | **Project Settings → API → Project API keys → anon public** |
| `DAHOAM_BAUFPLAN_EMAIL_TO` (optional) | Beliebige E-Mail-Adresse von Ihnen |
| `DAHOAM_SITE_ORIGIN` (optional) | Nur nötig, wenn Passwort-Reset immer eine **feste** Basis-URL braucht, z. B. `https://www.ihre-domain.at` |

Ohne die ersten beiden Variablen schreibt der Build nur einen **leeren Stub** in `js/config.js` – dann schlägt Login mit „Supabase nicht konfiguriert“ fehl.

---

## 5) Datenbank-Tabellen und Rechte (SQL)

1. In Supabase: **SQL Editor** → **New query**.
2. Inhalt von **`supabase/schema.sql`** aus diesem Repository **vollständig** einfügen und **Run** ausführen.

Damit existieren u. a. `bauplan_auftraege` (Kontaktformular/Editor) und `kunden_pakete` (Mein Abo) inklusive **Row Level Security**.

### 5a) Kundenportal: eigene Website & Demo-Zahlungen

1. Im **SQL Editor** zusätzlich **`supabase/kunden-sites-portal-migration.sql`** einfügen und **Run** ausführen (idempotent; kann nach jedem `schema.sql`-Deploy nachgezogen werden).
2. **Woran Sie Erfolg erkennen:** Tabellen `paket_kontingente`, `kunden_sites`, `site_aenderungen_log`, `demo_zahlungen` existieren; in `paket_kontingente` stehen drei Zeilen (`starter`, `standard`, `premium`) mit Freikontingenten für Bild-/Text-Änderungen pro Monat.
3. **Kunden-UI:** Seite **`kunde-website.html`** (nach Login mit Kundenkonto). Unter **Authentication → URL Configuration → Redirect URLs** die URL dieser Seite erlauben (z. B. `https://www.ihre-domain.at/kunde-website.html` oder `https://www.ihre-domain.at/**`).
4. **GitHub / Cloudflare (noch manuell oder per eigenem Skript):** In `kunden_sites` gibt es Felder wie `github_repo_owner`, `github_repo_name`, `cloudflare_pages_project`, `live_url` – Platzhalter für eine spätere **Edge Function** mit Secrets (GitHub App, Cloudflare API), die Repo anlegt und Pages verbindet. Bis dahin: Repo/Deploy wie bisher von Hand pflegen und URLs in der Tabelle setzen (z. B. per SQL als `postgres`).

### 5b) Admin: Demo-Job aus Website-Anfrage (für Cursor-Agent 2)

1. SQL **`supabase/kunden-demo-jobs-migration.sql`** im Editor ausführen (nach 5a).
2. **admin.html** → Tab **„Kunden-Demos“** oder bei einer **Website-Anfrage** auf **„Demo-Job anlegen“** – es entsteht ein Eintrag in **`kunden_demo_jobs`** inkl. **Markdown-Brief** (`agent_brief_md`).
3. **„Agent-Brief kopieren“** → Inhalt in Cursor an den **zweiten Agenten** einfügen: der Brief beschreibt u. a. Repo **ohne** Supabase-Keys, statische Site, danach `kunden_pakete` + `kunden_sites` in **eurer** Supabase-Datenbank.
4. **Vollautomation „ein Klick = GitHub + Cloudflare“:** dafür braucht ihr eine **Supabase Edge Function** (oder CI) mit **GitHub App**-Token und **Cloudflare API**-Token – nicht Teil der statischen Website; die Tabelle `kunden_demo_jobs` ist die Queue/Referenz dafür.

---

## 6) Authentication – E-Mail & Bestätigung

1. **Authentication** → **Providers** → **Email** sollte **aktiviert** sein.
2. **Selbstregistrierung (Konto anlegen):** Die Seite **`konto-anlegen.html`** nutzt `signUp`. Dafür muss unter **Email** die Registrierung erlaubt sein (je nach Dashboard: Sign-ups / „Enable email confirmations“ – siehe Supabase-Doku zur jeweiligen Version). Nach Sign-up ggf. E-Mail bestätigen, bevor Login klappt.
3. **Authentication** → **Users**: hier legen Sie Benutzer manuell an (**Add user** → E-Mail + Passwort, optional „Auto Confirm User“ anhaken für erste Tests) – Alternative zur Selbstregistrierung.

**E-Mail-Bestätigung (Confirm sign up):**

- **Authentication** → **Providers** → **Email** → bei Bedarf **Confirm email** deaktivieren **nur für Tests**, damit Login sofort klappt.
- Für Produktion: Bestätigung **an** lassen und in **Authentication** → **Email Templates** prüfen, ob die Links zu Ihrer Domain passen.

---

## 7) Site URL und Redirect URLs (sehr wichtig)

Sonst schlagen **Login**, **Magic Links** oder **Passwort zurücksetzen** mit Redirect-Fehlern fehl.

1. **Authentication** → **URL Configuration**.
2. **Site URL** = die öffentliche Basis-URL Ihrer Website, z. B.  
   `https://www.ihre-domain.at`  
   (ohne Slash am Ende, mit `https`.)
3. **Redirect URLs** – jede Zeile eine URL, z. B.:

   - `https://www.ihre-domain.at/**`  
   - `https://ihre-domain.at/**`  
   - `https://*.pages.dev/**` (falls Sie Cloudflare Pages-Preview-URLs nutzen)  
   - für lokalen Test (VS Code Live Server):  
     `http://127.0.0.1:5500/**`  
     `http://localhost:5500/**`  
     (Port anpassen, falls Ihr Server anders läuft.)

4. **Passwort-Reset** leitet auf **`passwort-neu.html`** – diese Seite muss unter derselben Origin erreichbar sein, z. B.:  
   `https://www.ihre-domain.at/passwort-neu.html`  
   Diese URL (oder `…/**`) muss in **Redirect URLs** erlaubt sein.
5. **Konto anlegen** (`konto-anlegen.html`) bestätigt die E-Mail oft mit Weiterleitung zu **`mein-abo.html`** – dieselbe Domain muss in **Redirect URLs** erlaubt sein (z. B. `https://www.ihre-domain.at/**`).

Nach Änderungen an URLs: kurz warten und Seite neu laden; ggf. Browser-Cache leeren.

---

## 8) Zwei Arten von Konten (Überblick)

| Bereich | Seite | Wer meldet sich an? |
|--------|--------|----------------------|
| Team / intern | **admin.html**, **Anmelden** auf der Startseite (Editor-Zugang) | Nur Nutzer mit **Admin-Rolle** in Supabase (Schritt 8b) |
| Kunden | **mein-abo.html** | Jeder bestätigte Auth-User mit Zeile in **`kunden_pakete`** |

Technisch sind das **dieselbe** Supabase-**Authentication** (E-Mail + Passwort), getrennt über **App Metadata** (`role: admin`) und **Row Level Security** auf `bauplan_auftraege`. Kundenkonten haben **keine** Admin-Rolle und sehen keine Aufträge.

---

## 8a) Team-Benutzer anlegen (E-Mail + Passwort)

1. In Supabase: **Authentication** → **Users** → **Add user**.
2. **E-Mail** und **Passwort** eintragen.
3. Für erste Tests: **Auto Confirm User** anhaken (sonst E-Mail bestätigen, siehe Schritt 6).
4. **Woran Sie Erfolg erkennen:** Der User erscheint in der Liste; Login mit diesen Daten auf **mein-abo.html** ist möglich (ohne Paket-Zeile erscheint der Hinweis „noch kein Abo verknüpft“ – das ist normal, bis Schritt 9 erledigt ist).

---

## 8b) Team-Admin-Rolle setzen (Pflicht für Admin & Startseiten-Login)

Ohne diese Rolle blockiert die Datenbank **Lesen** und **Schreiben** von `bauplan_auftraege` für eingeloggte Nicht-Admins.

**Variante A – SQL (empfohlen)**

1. Datei **`supabase/set-admin-role.sql`** im Repo öffnen.
2. Die Platzhalter-E-Mail durch die **Team-E-Mail** ersetzen (derselbe User wie in 8a).
3. In Supabase: **SQL** → **New query** → Inhalt einfügen → **Run**.
4. **Woran Sie Erfolg erkennen:** Abfrage `select email, raw_app_meta_data from auth.users where lower(email) = lower('ihre@team-mail.at');` zeigt in `raw_app_meta_data` den Eintrag `"role":"admin"`.

**Variante B – Dashboard**

1. **Authentication** → **Users** → gewünschten User öffnen.
2. Unter **User Management** / Metadaten: **App Metadata** (raw) um `"role":"admin"` ergänzen (JSON-Objekt, Kommas beachten) und speichern – je nach UI-Version heißt das Feld z. B. **App metadata** oder **raw_app_meta_data** in SQL.

**Danach:** Einmal **abmelden** und neu einloggen (oder kurz warten), damit der JWT die neue Rolle enthält.

**Test:** **admin.html** öffnen → mit Team-Konto einloggen → Tabelle „Aufträge“ lädt ohne RLS-Fehler. Mit einem **reinen Kundenkonto** (ohne `role: admin`) darf **admin.html** keinen Inhalt der Aufträge zeigen.

---

## 9) Kundenkonto für „Mein Abo“

1. **Authentication** → **Users** → **Add user** (eigene E-Mail des Kunden, eigenes Passwort, bestätigen wie oben). **Keine** Admin-Rolle setzen (Kunde soll nur `kunden_pakete` sehen).
2. User-ID kopieren: In der Benutzerliste auf den User klicken → UUID steht in der URL oder in den User-Details.
3. **SQL Editor** – eine Zeile einfügen (Platzhalter ersetzen):

```sql
insert into public.kunden_pakete (user_id, paket_code, paket_name, monatspreis, status, vertragsbeginn)
values (
  'HIER-DIE-UUID-DES-USERS'::uuid,
  'standard',
  'Mittel',
  39.00,
  'aktiv',
  current_date
);
```

4. Kunde meldet sich unter **mein-abo.html** an und sieht das Paket.

---

## 10) Passwort vergessen testen

1. Auf **passwort-neu.html** (oder Link „Passwort vergessen“ auf Login-Seiten) E-Mail eingeben → **Link anfordern**.
2. E-Mail-Postfach prüfen (auch Spam) → Link klicken.
3. Neues Passwort setzen → die Seite leitet **Kunden** zu **mein-abo.html** und **Team-Admins** zu **admin.html** weiter.

Funktioniert der Link nicht: Redirect URLs und Site URL prüfen (Schritt 7).

---

## 11) Häufige Fehler

| Symptom | Typische Ursache |
|--------|-------------------|
| „Supabase nicht konfiguriert“ / leere Keys | Lokal fehlt `js/config.js`; live fehlen Cloudflare-Umgebungsvariablen oder Deploy nicht neu gebaut. |
| „Invalid login credentials“ | Falscher Benutzername/Passwort; oder E-Mail noch nicht bestätigt. |
| Redirect / URL-Fehler nach E-Mail-Link | **Redirect URLs** in Supabase unvollständig; **Site URL** falsch. |
| „Mein Abo“: kein Paket sichtbar | Keine Zeile in `kunden_pakete` für diese `user_id`; oder SQL aus `schema.sql` nicht ausgeführt. |
| Tabelle existiert nicht | `schema.sql` nicht ausgeführt oder falscher Supabase-Projekt-Tab. |
| Admin: „permission denied“ / RLS / keine Zeilen | Policies aus aktuellem `schema.sql` ausführen; **Admin-Rolle** (Schritt 8b) setzen und **neu einloggen**. |
| Editor: Speichern in DB schlägt fehl | Als **Team-Admin** auf der Startseite anmelden **oder** abmelden (dann anonymes `INSERT` wie Gast). |

---

## 12) Kurz-Checkliste vor Go-Live

- [ ] `schema.sql` im Supabase SQL Editor ausgeführt (Policies aktuell)  
- [ ] `DAHOAM_SUPABASE_URL` + `DAHOAM_SUPABASE_ANON_KEY` auf Cloudflare gesetzt, Deploy neu  
- [ ] **Site URL** = Produktions-URL  
- [ ] **Redirect URLs** inkl. `https://ihre-domain.at/**` und `…/passwort-neu.html`  
- [ ] **Team:** User angelegt **und** `role: admin` gesetzt (`set-admin-role.sql` oder Dashboard)  
- [ ] **Kunde:** User ohne Admin-Rolle + Zeile in `kunden_pakete`  
- [ ] Passwort-Reset einmal durchklicken  

Bei Bedarf später: **Custom SMTP** unter Project Settings → Auth, damit Absender und Zustellrate professioneller werden.
