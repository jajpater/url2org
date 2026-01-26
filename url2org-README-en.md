# `url2org` – Capture webpages to Org-mode, Markdown, Typst, LaTeX or DOCX

A lightweight, fully local toolchain to **convert webpages to well-formatted notes** with one click from Chrome or Brave — without mouse, browser extensions, or network servers.
Designed for a **mouseless**, **Wayland-friendly** workflow with **Wofi launcher**.

---

## 🌐 Component Overview

| Script             | Purpose                                              | Type   | Invocation                      |
| ------------------ | ---------------------------------------------------- | ------ | ------------------------------- |
| `url2org`          | Core script: URL → `.org`, `.md`, `.typ` or `.docx`  | Python | `url2org [URL] [options]`       |
| `wofi-cap-url2org` | Wofi menu (Wayland dmenu-style) with interactive toggles | Bash   | `wofi-cap-url2org [URL]`        |
| `url2org-proto`    | Protocol handler for `url2org://capture?...`         | Bash   | via browser link or bookmarklet |

---

## 🧠 1. `url2org` — the core

### Function

Converts a webpage into a structured note with metadata.

### Features

* Extraction via **Trafilatura** (Markdown) or **Readability** (HTML).
* Conversion via **Pandoc** to Org, Markdown, Typst, LaTeX or DOCX.
* Post-processing of "soft line breaks" and automatic wrap around 65 columns (disable with `--no-fill`).
* Snapshot function (save HTML alongside the note).
* Automatic title and date detection.

### Usage

```bash
url2org URL [--dir DIR] [--open] [--snapshot] [--readability] [--format org|markdown|typst|latex|docx]
```

### Main Options

| Option              | Description                               |
| ------------------- | ----------------------------------------- |
| `--dir DIR`         | Target directory                          |
| `--name`            | Filename                                  |
| `--open`            | Open in `emacsclient`                     |
| `--snapshot`        | Download original HTML                    |
| `--readability`     | Use Readability instead of Trafilatura    |
| `--append FILE.org` | Append entry to existing file             |
| `--format`          | Choice: `org`, `markdown`, `typst`, `docx`|
| `--no-unwrap`       | Disable automatic unwrap                  |
| `--no-softfix`      | Disable line fixing                       |
| `--no-fill`         | Disable wrapping around 65 columns        |
| `--debug`           | Extra log output                          |

---

## 💠 2. `wofi-cap-url2org` — interactive dmenu-style launcher

### Purpose

A **Wofi menu** (Wayland) that does everything in one window:
URL → directory → options → format → capture.

### Interface

* **Step 1:** Choose clipboard URL or type manually.
* **Step 2:** Fuzzy-select a directory (fd/find).
* **Step 3:** Interactive menu with toggles:
  * `[x] --open`
  * `[x] --snapshot`
  * `[x] --readability`
* Format choice: `[ ] org`, `[ ] markdown`, `[ ] typst`, `[ ] latex`, `[ ] docx` (multiple allowed)
* **Step 4:** Capture via `url2org`.

### Keyboard Behavior

* **Enter** → confirm choice or start directly.
* **Tab/arrows** → switch between options.
* **Esc** → cancel.

> Tip: Want to use spacebar to toggle options? Add `keybindings/select=Return,space` to `~/.config/wofi/config`.

---

## 🔗 3. `url2org-proto` — protocol handler

### Purpose

Connects the custom schema `url2org://capture?...` to your local scripts.

### Function

* Parses `url=` parameter (required).
* Starts interactive flow via `wofi-cap-url2org`.

### Behavior

`url2org://capture?url=…` → interactive flow via `wofi-cap-url2org`

### Desktop Registration

With Nix flake installation, the desktop entry is automatically registered. For manual setup:

```ini
[Desktop Entry]
Name=URL to Org Capture
Exec=url2org-proto %u
Type=Application
NoDisplay=true
MimeType=x-scheme-handler/url2org;
```

Activate:

```bash
xdg-mime default url2org.desktop x-scheme-handler/url2org
```

---

## 🔖 4. Bookmarklets

### Standard (interactive UI)

```javascript
javascript:location.href='url2org://capture?url='+encodeURIComponent(location.href)
```

### With edit flag

```javascript
javascript:location.href='url2org://capture?url='+encodeURIComponent(location.href)+'&edit=1'
```

To create a bookmarklet:
1. Create a new bookmark in your browser
2. Name it (e.g., "Capture to Org")
3. Paste the JavaScript code as the URL

---

## ⚙️ 5. Dependencies

When installed via Nix flake, all dependencies are bundled automatically:

| Tool / Lib                                          | Purpose                        |
|-----------------------------------------------------|--------------------------------|
| **Python ≥3.10**                                    | runtime                        |
| **trafilatura**, **readability-lxml**, **requests** | extraction                     |
| **pandoc**                                          | format conversion              |
| **wget**                                            | snapshot download              |
| **wofi**                                            | fuzzy directory picker         |
| **wl-paste**                                        | clipboard reading              |
| **notify-send**                                     | desktop notifications          |
| **fd**                                              | fast directory listing         |

---

## 💡 6. Workflow Summary

| Action                   | Tool                               |
|--------------------------|------------------------------------|
| Bookmark "Capture → Org" | `url2org://capture?url=...`        |
| Interactive via launcher | `wofi-cap-url2org`                 |
| Core storage & extraction| `url2org`                          |

---

## ⚙️ 7. Variables and Defaults

| Variable         | Meaning                               | Default              |
|------------------|---------------------------------------|----------------------|
| `URL2ORG_BIN`    | path to main script                   | `url2org` (in PATH)  |
| `WOFI_CAP`       | path to wofi capture script           | `wofi-cap-url2org`   |
| `ROOTS`          | start directories for fuzzy picker    | `~/Documents/...`    |
| `HIDE_DOTDIRS`   | hide hidden directories               | `true`               |

---

## 🧩 8. Possible Extensions

* **Automatic blog recognition:**

  ```bash
  case "$URL" in
    *wordpress.com*|*medium.com*) DEFAULT_FLAGS="--readability" ;;
  esac
  ```
* **Inbox routing per domain:**
  save WordPress articles in `~/Documents/org/blogs`.
* **Extra hooks:** open Emacs directly with capture template.

---

## 💬 9. Known Benefits

✅ Fully local, without extensions or servers
✅ Direct or interactive capture from bookmarks
✅ Almost Mouseless – every variant keyboard-friendly
✅ Wayland-compatible (wofi, fuzzel, tofi)
✅ Robust error handling with clear logs
✅ Supports multiple formats (Org, Markdown, Typst, Docx)
✅ Full control over destination, format and workflow
✅ Integrates seamlessly with Emacs or other editors

---

## ⚙️ 10. Troubleshooting

### Wayland / Wofi Issues

**Wofi shows empty bar or Gtk-CRITICAL errors:**
- Try `fuzzel` or `tofi` as alternatives
- Check if your compositor has focus restrictions

**Clipboard doesn't work:**
- Ensure `wl-clipboard` is available (bundled with Nix flake)
- Check if `$WAYLAND_DISPLAY` is set

### Protocol Issues

**Chrome says "Unknown protocol: url2org://":**
```bash
xdg-mime default url2org.desktop x-scheme-handler/url2org
```

**Bookmarklet opens but nothing happens:**
- Use Bookmarks Bar (not address bar)
- Click directly on the bookmark icon

### Performance

**Directory listing too slow:**
- Limit `ROOTS` in the script to relevant directories
- Set `HIDE_DOTDIRS=true`

### Diagnostic Command

```bash
url2org "https://example.com" --readability --format org --debug
```

If this successfully creates an `.org` file, the entire chain works (Python, Pandoc, permissions, network).

---

## License

MIT License — free to use and modify.
