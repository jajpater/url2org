# `url2org` – Capture webpagina’s naar Org-mode, Markdown, Typst, LaTeX of DOCX

Een lichtgewicht, volledig lokale toolchain om met één klik vanuit Chrome of Brave webpagina’s te **converteren naar goed opgemaakte notities** — zonder muis, zonder browser-extensies en zonder netwerkservers.
Ontworpen voor een **mouseless**, **Wayland-vriendelijke** workflow met **fzf-, Wofi- of Zenity-launchers**.

---

## 🌐 Overzicht van de onderdelen

| Script             | Doel                                                       | Type   | Invocatie                       |
| ------------------ | ---------------------------------------------------------- | ------ | ------------------------------- |
| `url2org`          | Kernscript: URL → `.org`, `.md`, `.typ` of `.docx`         | Python | `url2org [URL] [opties]`        |
| `wofi-cap-url2org` | Wofi-menu (Wayland dmenu-stijl) met interactieve toggles   | Bash   | `wofi-cap-url2org [URL]`        |
| `url2org-proto`    | Protocol-handler voor `url2org://capture?...`              | Bash   | via browser-link of bookmarklet |

---

## 🧠 1. `url2org` — de kern

### Functie

Zet een webpagina om in een gestructureerde notitie met metadata.

### Kenmerken

* Extractie via **Trafilatura** (Markdown) of **Readability** (HTML).
* Conversie via **Pandoc** naar Org, Markdown, Typst, LaTeX of DOCX.
* Postprocessing van “soft line breaks” en automatische wrap rond 65 kolommen (uit te zetten met `--no-fill`).
* Snapshotfunctie (bewaar HTML naast de notitie).
* Automatische titel- en datumdetectie.

### Gebruik

```bash
url2org URL [--dir DIR] [--open] [--snapshot] [--readability] [--format org|markdown|typst|latex|docx]
```

### Belangrijkste opties

| Optie               | Uitleg                                    |
| ------------------- | ----------------------------------------- |
| `--dir DIR`         | Doelmap                                   |
| `--name`            | Bestandsnaam                              |
| `--open`            | Open in `emacsclient`                     |
| `--snapshot`        | Download originele HTML                   |
| `--readability`     | Gebruik Readability i.p.v. Trafilatura    |
| `--append DOEL.org` | Voeg entry toe aan bestaand bestand       |
| `--format`          | Keuze: `org`, `markdown`, `typst`, `docx` |
| `--no-unwrap`       | Zet automatische unwrap uit               |
| `--no-softfix`      | Zet linefixing uit                        |
| `--no-fill`         | Zet wrapping rond 65 kolommen uit         |
| `--debug`           | Extra loguitvoer                          |

---

## 💠 2. `wofi-cap-url2org` — interactieve dmenu-style launcher

### Doel

Een **Wofi-menu** (Wayland) dat alles in één venster doet:
URL → directory → opties → formaat → capture.

### Interface

* **Stap 1:** Kies clipboard-URL of typ handmatig.
* **Stap 2:** Fuzzy-selecteer een directory (fd/find).
* **Stap 3:** Interactief menu met toggles:

  * `[x] --open`
  * `[x] --snapshot`
  * `[x] --readability`
* Formaatkeuze: `[ ] org`, `[ ] markdown`, `[ ] typst`, `[ ] latex`, `[ ] docx` (meerdere tegelijk mogelijk)
* **Stap 4:** Capture via `url2org`.

### Sneltoetsgedrag

* **Enter** → bevestig keuze of start direct.
* **Tab/pijltjes** → wisselen tussen opties.
* **Esc** → annuleer.

> Tip: Wil je de spatiebalk gebruiken om opties te toggelen? Voeg in `~/.config/wofi/config` iets als `keybindings/select=Return,space` toe zodat zowel Enter als spatie het geselecteerde item toggelen.

### Configuratie

Bovenin het script:

```bash
ROOTS=("$HOME/Documents/org" "$HOME/Documents")
HIDE_DOTDIRS=true
URL2ORG_BIN="$HOME/.local/bin/url2org"
```

### Gebruik

```bash
wofi-cap-url2org
wofi-cap-url2org "https://example.com"
```

---

## 🔗 3. `url2org-proto` — protocol handler

### Korte verschillen tussen de protocol‑handlers

Simpele parse: verwacht `url=` als laatste param; roept `wofi-cap-url2org` uit deze repo aan.

Welke versie actief is bepaal je in `url2org.desktop` bij de `Exec=` regel.

### Doel

Verbindt het custom schema `url2org://capture?...` met je lokale scripts.

### Functie

* Parseert `url=` parameter (verplicht) en `quick=` (optioneel).
* Start **quick**- of **hybrid**-flow afhankelijk van parameter.

### Gedrag

`url2org://capture?url=…`          interactieve flow via `hybrid-url2org`

### Desktop-registratie

```ini
[Desktop Entry]
Name=URL → Org Capture
Exec=/home/jajpater/.local/bin/url2org-proto %u
Type=Application
NoDisplay=true
MimeType=x-scheme-handler/url2org;
```

Activeer:

```bash
xdg-mime default url2org.desktop x-scheme-handler/url2org
```

---

## 🔖 8. Bookmarklets

### Snel (geen UI)

```javascript
javascript:location.href='url2org://capture?url='+encodeURIComponent(location.href)
```

### Edit-modus (volledige interactie)

```javascript
javascript:location.href='url2org://capture?url='+encodeURIComponent(location.href)+'&edit=1'
```

---

## ⚙️ 9. Afhankelijkheden

| Tool / Lib                                          | Doel                           | Installatie                                         |
| --------------------------------------------------- | ------------------------------ | --------------------------------------------------- |
| **Python ≥3.10**                                    | runtime                        | —                                                   |
| **trafilatura**, **readability-lxml**, **requests** | extractie                      | `pip install trafilatura readability-lxml requests` |
| **pandoc**                                          | conversie naar andere formaten | `sudo apt install pandoc`                           |
| **wget**                                            | snapshot-download              | `sudo apt install wget`                             |
| **zenity**                                          | lichte GUI-vensters            | `sudo apt install zenity`                           |
| **tofi** / **fuzzel** / **rofi-wayland**            | fuzzy directory-picker         | `sudo apt install tofi`                             |
| **wl-paste** / **xclip**                            | clipboard lezen                | `sudo apt install wl-clipboard`                     |
| **notify-send**                                     | desktopnotificaties            | `sudo apt install libnotify-bin`                    |
| **fd** of **fdfind**                                | snelle directorylijst          | `sudo apt install fd-find`                          |

---

## 💡 10. Workflow-samenvatting

| Actie                    | Tool                               |
|--------------------------|------------------------------------|
| Bookmark “Snel → Org”    | `url2org://capture?url=...`        |
| Bookmark “Edit → Org”    | `url2org://capture?url=...&edit=1` |
| Interactief via launcher | `wofi-cap-url2org`                 |
| Kernopslag en extractie  | `url2org`                          |

---

## ⚙️ 11. Variabelen en defaults

| Variabele        | Betekenis                                | Default                |
| ---------------- | ---------------------------------------- | ---------------------- |
| `DEFAULT_DIR`    | standaardmap voor `url2org-quick`        | `~/Documents/org`      |
| `DEFAULT_FORMAT` | uitvoerformaat (org/md/typst/docx)       | `org`                  |
| `DEFAULT_FLAGS`  | extra argumenten (bijv. `--readability`) | *(leeg)*               |
| `DEFAULT_ROOT`   | startdirectory voor fuzzy picker         | `~/Documents/org`      |
| `URL2ORG_BIN`    | pad naar hoofdscript                     | `~/.local/bin/url2org` |
| `HIDE_DOTDIRS`   | verberg verborgen directories            | `true`                 |

---

## 🔮 12. Roadmap / wensen

- `wofi-cap-url2org`: mogelijkheid om een nieuwe map aan te maken wanneer je een niet-bestaand pad intypt (zonder vooraf alles te cachen).
- `wofi-cap-url2org`: append-flow naar een bestaand Org-bestand (keuze via bestandsselector) zodat `--append` vanuit de launcher beschikbaar wordt.
- Extra heuristieken voor Org-postprocessing als er concrete probleem-sites gemeld worden.
- Optionele “ snelle capture + edit in Emacs” flow (denk aan automatische `emacsclient` capture template).

---

## 🧩 13. Mogelijke uitbreidingen

* **Automatische herkenning van blogs:**

  ```bash
  case "$URL" in
    *wordpress.com*|*medium.com*) DEFAULT_FLAGS="--readability" ;;
  esac
  ```
* **Inbox-routing per domein:**
  sla WordPress-artikelen bijv. in `~/Documents/org/blogs`.
* **Extra hooks:** open Emacs direct met capture-template.

---

## 💬 13. Bekende voordelen

✅ Volledig lokaal, zonder extensies of servers
✅ Directe of interactieve capture vanuit bookmarks
✅ Almost Mouseless – elke variant toetsenbordvriendelijk
✅ Wayland-compatibel (tofi, wofi, zenity)
✅ Robuuste foutafhandeling met duidelijke logs
✅ Ondersteunt meerdere formaten (Org, Markdown, Typst, Docx)
✅ Volledige controle over bestemming, formaat en workflow
✅ Integreert naadloos met Emacs of andere editors

---

## ⚙️ 14. Troubleshooting

Hieronder vind je de meest voorkomende problemen, oorzaken en oplossingen.

---

### 🧩 A. **Wayland / Wofi / gerelateerde problemen**

#### 1. Wofi toont “Gtk-CRITICAL: gtk_widget_grab_focus” of een lege balk

**Oorzaak:** Wofi mist een geldige focus of compositor context.
**Oplossing:**

* Gebruik **tofi** of **fuzzel** als vervanger (stabieler onder Wayland).
* Start Wofi met `wofi --show drun` om te testen of focus werkt.
* Controleer of je compositor (bijv. Sway, Hyprland) geen focusbeperkingen heeft voor nested GUIs.

#### 2. Clipboard werkt niet in Wayland

**Foutmelding:**

```
(process:1234): X11Helper-WARNING **: Failed to convert selection
```

**Oorzaak:** `xclip` probeert te werken in een Wayland-sessie zonder XWayland context.
**Oplossing:**

* Installeer en gebruik `wl-clipboard` in plaats van `xclip`:

  ```bash
  sudo apt install wl-clipboard
  ```
* Controleer of `$WAYLAND_DISPLAY` is ingesteld (`echo $WAYLAND_DISPLAY`).


---

### ⚡ B. **Python of Trafilatura fouten**

#### 1. “ModuleNotFoundError: No module named 'trafilatura'”

**Oorzaak:** De Python virtualenv van `url2org` mist de juiste modules.
**Oplossing:**

```bash
/home/jajpater/.pyenv/versions/url2org/bin/python -m pip install \
  trafilatura readability-lxml requests
```

#### 2. “lxml downgrade / dependency conflict”

**Symptoom:** bij installatie wordt `lxml` gedowngraded en andere pakketten breken.
**Oplossing:**

* Gebruik een **afzonderlijke venv** voor `url2org`.
* Herinstalleer met:

  ```bash
  python -m venv ~/.local/venv/url2org
  source ~/.local/venv/url2org/bin/activate
  pip install trafilatura readability-lxml requests pandocfilters
  ```

#### 3. Pandoc converteert niet of geeft lege output

**Oorzaak:** Pandoc niet geïnstalleerd of verkeerde versie.
**Controle:**

```bash
pandoc -v
```

**Oplossing:**

```bash
sudo apt install pandoc
```

of installeer via conda/gh-release voor de nieuwste versie.

---

### 🧭 C. **Bookmarklet / protocolproblemen**

#### 1. Chrome zegt: “Unknown protocol: url2org://”

**Oorzaak:** het `x-scheme-handler/url2org` protocol is nog niet geregistreerd.
**Oplossing:**

```bash
xdg-mime default url2org.desktop x-scheme-handler/url2org
```

Controleer:

```bash
xdg-mime query default x-scheme-handler/url2org
```

#### 2. Protocol werkt, maar URL is niet gedecodeerd

**Oorzaak:** bookmarklet encodeert URL niet correct of handler mist decode stap.
**Oplossing:** controleer of de regel in `url2org-proto` aanwezig is:

```bash
URL="$(python3 -c 'import sys,urllib.parse as u;print(u.unquote(sys.argv[1]))' "$ENC_URL")"
```

#### 3. Bookmarklet opent maar doet niets

**Oorzaak:** de browser blokkeert custom protocols zonder gebruikersactie.
**Oplossing:**

* Gebruik **Bookmarks Bar** (niet een sneltoets).
* Klik direct op het bookmark-icoon, niet via adresbalk.

---

### 📁 D. **Opslag- of rechtenproblemen**

#### 1. “Geen schrijfrechten in: /pad/naar/map”

**Oorzaak:** map bestaat niet of is niet toegankelijk.
**Oplossing:**

* Controleer met `ls -ld /pad/naar/map`.
* Maak de map handmatig aan of wijzig in het script:

  ```bash
  mkdir -p "$CHOICE_DIR"
  ```

#### 2. “Bestand bestaat al” → krijgt suffix `-2.org`

**Gedrag:** correct — `url2org` vermijdt overschrijven door automatisch te nummeren.
**Oplossing:** indien ongewenst, gebruik `--name` of verwijder oudere versies.

---

### 🧩 E. **Performance & optimalisatie**

#### 1. “Te traag bij directory-lijst”

**Oorzaak:** `find` of `fd` scant hele `$HOME`.
**Oplossing:**

* Beperk `ROOTS` in `wofi-cap-url2org` of `hybrid-url2org` tot relevante directories:

  ```bash
  ROOTS=("$HOME/Documents/org" "$HOME/Documents/Preken")
  ```
* Zet eventueel `HIDE_DOTDIRS=true`.

#### 2. “Pandoc gebruikt veel CPU bij docx/typst export”

**Oorzaak:** conversie is zwaarder dan plain Org.
**Oplossing:**

* Gebruik `--format org` of `--format markdown` bij standaard captures.
* Voor bulkexport: voer `pandoc` achteraf asynchroon uit (batchverwerking).

---

### 🧩 F. **Algemene debug-tips**

* Voeg `set -x` bovenaan je Bash-script toe om uitvoer te volgen.
* Draai met `--debug` bij `url2org` om extractieproces te volgen.
* Controleer tijdelijke bestanden in `/tmp` als extractie mislukt.
* Bekijk `journalctl --user-unit=pipewire` als audio/clipboard-apps vastlopen (Wayland).
* Herstart `xdg-desktop-portal` als custom protocols niet reageren:

  ```bash
  systemctl --user restart xdg-desktop-portal
  ```

---

### 💡 Diagnostisch commando (snelle test)

```bash
url2org "https://example.com" --readability --format org --debug
```

Als dit succesvol een `.org`-bestand maakt, werkt de hele keten (Python, Pandoc, permissies, netwerk).

---
---

### Auteur & licentie

Samenstelling: **J.A.J. Pater**, 2025
MIT-licentie — vrij te gebruiken en aan te passen.
