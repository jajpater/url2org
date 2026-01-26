# url2org

Capture webpages to Org-mode, Markdown, Typst, LaTeX or DOCX.

## Installation (NixOS Flake)

Add to your `flake.nix` inputs:

```nix
{
  inputs = {
    url2org = {
      url = "github:jajpater/url2org";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Add to your home-manager packages:

```nix
{ url2org, pkgs, ... }:

{
  home.packages = [
    url2org.packages.${pkgs.system}.default
  ];

  # Register protocol handler
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/url2org" = "url2org.desktop";
    };
  };
}
```

All dependencies (Python packages, pandoc, wofi, etc.) are bundled automatically.

## Commands

| Command | Description |
|---------|-------------|
| `url2org` | CLI tool - capture URL to file |
| `wofi-cap-url2org` | Interactive capture with wofi menu |
| `url2org-proto` | Protocol handler for `url2org://` URLs |

## Usage

### CLI

```bash
# Basic usage
url2org https://example.com

# Specify output directory and format
url2org https://example.com --dir ~/Documents --format org

# Available formats: org, markdown, typst, latex, docx
url2org https://example.com --format markdown

# Use Readability for cleaner extraction
url2org https://example.com --readability

# Save HTML snapshot alongside
url2org https://example.com --snapshot

# Open in Emacs after saving
url2org https://example.com --open
```

### Interactive (wofi)

```bash
wofi-cap-url2org
```

This opens a wofi menu where you can:
1. Use clipboard URL or type manually
2. Choose destination directory
3. Toggle options (--open, --snapshot, --readability)
4. Select output format(s)

### Browser Integration (Bookmarklets)

Create a bookmark with this JavaScript as the URL:

```javascript
javascript:location.href='url2org://capture?url='+encodeURIComponent(location.href)
```

This calls the protocol handler which opens the interactive wofi menu.

**Setup:**
1. Create a new bookmark in Chrome/Brave
2. Name it (e.g., "Capture to Org")
3. Paste the JavaScript code as the URL
4. Click the bookmark on any page to capture it

## Dependencies (bundled)

The flake automatically includes:
- Python with trafilatura, readability-lxml, requests, lxml, cssselect
- pandoc (format conversion)
- wget (snapshots)
- wofi (interactive menu)
- fd, wl-clipboard, libnotify, coreutils, sed, awk, grep

## Development

```bash
nix develop  # Enter dev shell with all dependencies
```

## Documentation

For detailed documentation including troubleshooting, configuration options, and workflow examples:

- **English**: [url2org-README-en.md](url2org-README-en.md)
- **Nederlands**: [url2org-README-nl.md](url2org-README-nl.md)

## License

MIT
