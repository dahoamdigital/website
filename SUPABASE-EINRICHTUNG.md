# Supabase einrichten – Schritt für Schritt

Damit **Anmelden** (Startseite, Admin), **Mein Abo** und **Passwort zurücksetzen** funktionieren, brauchen Sie ein Supabase-Projekt, die **anon**-Keys in der Website und passende **Auth-URLs**. Arbeiten Sie die Schritte der Reihe nach ab.

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

## 3) Keys lokal eintragen (zum Testen am PC)

1. Im Ordner `website/js`: Datei **`config.example.js`** nach **`config.js`** kopieren.
2. In **`config.js`** eintragen:
   - `window.DAHOAM_SUPABASE_URL` = Ihre Project URL  
   - `window.DAHOAM_SUPABASE_ANON_KEY` = Ihr anon-Key  
3. Optional: `window.DAHOAM_BAUFPLAN_EMAIL_TO` = Ihre E-Mail (Vorbefüllung im Login).
4. Optional: Wenn Ihre **öffentliche** Website-URL von der Adresse abweicht, unter der Sie testen (selten):  
   `window.DAHOAM_SITE_ORIGIN = 'https://www.ihre-domain.at';`  
   Sonst wird für Passwort-Reset automatisch `window.location.origin` verwendet.

`config.js` liegt in **`.gitignore`** und wird nicht ins Git hochgeladen.

---

## 4) Keys auf Cloudflare Pages (Live-Seite)

1. Cloudflare → **Workers & Pages** → Ihr Projekt → **Settings** → **Environment variables**.
2. Für **Production** (und bei Bedarf **Preview**) anlegen:
   - `DAHOAM_SUPABASE_URL` = Project URL  
   - `DAHOAM_SUPABASE_ANON_KEY` = anon public key  
   - optional `DAHOAM_BAUFPLAN_EMAIL_TO`  
   - optional `DAHOAM_SITE_ORIGIN` = z. B. `https://www.ihre-domain.at` (wenn die Reset-Mail immer auf die Live-Domain zeigen soll)
3. **Save** → **Deployments** → letztes Deployment **Retry deployment** (oder leeren Commit pushen).

Ohne diese Variablen schreibt der Build nur einen **leeren Stub** in `js/config.js` – dann schlägt Login mit „Supabase nicht konfiguriert“ fehl.

---

## 5) Datenbank-Tabellen und Rechte (SQL)

1. In Supabase: **SQL Editor** → **New query**.
2. Inhalt von **`supabase/schema.sql`** aus diesem Repository **vollständig** einfügen und **Run** ausführen.

Damit existieren u. a. `bauplan_auftraege` (Kontaktformular/Editor) und `kunden_pakete` (Mein Abo) inklusive **Row Level Security**.

---

## 6) Authentication – E-Mail & Bestätigung

1. **Authentication** → **Providers** → **Email** sollte **aktiviert** sein.
2. **Authentication** → **Users**: hier legen Sie Benutzer an (**Add user** → E-Mail + Passwort, optional „Auto Confirm User“ anhaken für erste Tests).

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

Nach Änderungen an URLs: kurz warten und Seite neu laden; ggf. Browser-Cache leeren.

---

## 8) Team-Admin für „Aufträge“ (admin.html)

1. **Authentication** → **Users** → **Add user**.
2. E-Mail + Passwort vergeben → bei Tests **Auto Confirm User** anhaken.
3. Mit diesen Daten auf **admin.html** oder über **Anmelden** auf der Startseite einloggen.

Hinweis: Die RLS-Policy für `bauplan_auftraege` erlaubt allen **eingeloggten** Nutzern das Lesen der Aufträge. Nutzen Sie für Kunden **separate** E-Mail/Passwort-Konten nur für **Mein Abo**, nicht dieselben Zugänge wie das Team.

---

## 9) Kundenkonto für „Mein Abo“

1. **Authentication** → **Users** → **Add user** (eigene E-Mail des Kunden, eigenes Passwort, bestätigen wie oben).
2. User-ID kopieren: In der Benutzerliste auf den User klicken → UUID steht in der URL oder in den User-Details.
3. **SQL Editor** – eine Zeile einfügen (Platzhalter ersetzen):

```sql
insert into public.kunden_pakete (user_id, paket_code, paket_name, monatspreis, status, vertragsbeginn)
values (
  'HIER-DIE-UUID-DES-USERS'::uuid,
  'standard',
  'Standard',
  89.00,
  'aktiv',
  current_date
);
```

4. Kunde meldet sich unter **mein-abo.html** an und sieht das Paket.

---

## 10) Passwort vergessen testen

1. Auf **passwort-neu.html** (oder Link „Passwort vergessen“ auf Login-Seiten) E-Mail eingeben → **Link anfordern**.
2. E-Mail-Postfach prüfen (auch Spam) → Link klicken.
3. Neues Passwort setzen → anschließend unter **mein-abo.html** / **admin.html** einloggen.

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

---

## 12) Kurz-Checkliste vor Go-Live

- [ ] `schema.sql` im Supabase SQL Editor ausgeführt  
- [ ] `DAHOAM_SUPABASE_URL` + `DAHOAM_SUPABASE_ANON_KEY` auf Cloudflare gesetzt, Deploy neu  
- [ ] **Site URL** = Produktions-URL  
- [ ] **Redirect URLs** inkl. `https://ihre-domain.at/**` und `…/passwort-neu.html`  
- [ ] Admin-User + mindestens ein Test-Kunde mit `kunden_pakete`-Zeile  
- [ ] Passwort-Reset einmal durchklicken  

Bei Bedarf später: **Custom SMTP** unter Project Settings → Auth, damit Absender und Zustellrate professioneller werden.
