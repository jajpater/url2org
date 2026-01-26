# wofi-cap-url2org - Interactieve URL capture met wofi
# URL2ORG_BIN wordt door de Nix wrapper gezet

# ---------- Instellingen ----------
WOFI_BIN="${WOFI_BIN:-wofi}"
FD_BIN="${FD_BIN:-fd}"

# URL2ORG_BIN wordt door de wrapper gezet, gebruik fallback voor testing
: "${URL2ORG_BIN:?URL2ORG_BIN must be set}"

ROOTS=("$HOME/Documents/Aantekeningen/Org/web" "$HOME/Documents" "$HOME")
HIDE_DOTDIRS=true

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/url2org"
MRU_FILE="$CACHE_DIR/dirs.txt"
mkdir -p "$CACHE_DIR"; touch "$MRU_FILE"

PROMPT_URL="URL invoer"
PROMPT_DIR="Kies doelmap"
PROMPT_FLAGS="Opties & formaat (Enter toggelt; kies KLAAR als je klaar bent)"
# -----------------------------------

die(){ echo "ERROR: $*" >&2; exit 1; }
need(){ command -v "$1" >/dev/null 2>&1 || die "$1 niet gevonden"; }

need "$WOFI_BIN"
[ -x "$URL2ORG_BIN" ] || die "url2org niet gevonden op $URL2ORG_BIN"

# ----- wofi helper (geen markup i.v.m. & in paden) -----
wofi_pick() {
  # stdin -> lijst; stdout -> keuze; exit nonzero bij cancel
  "$WOFI_BIN" --dmenu --prompt "$1" --insensitive --cache-file /dev/null
}

# ----- Clipboard (Wayland) -----
get_clipboard_raw() {
  if command -v wl-paste >/dev/null 2>&1; then
    wl-paste --no-newline 2>/dev/null || true
  else
    echo ""
  fi
}
is_url(){ grep -qiE '^https?://'; }

# ----- 1) URL: via argv of via (clipboard/handmatig) -----
if [ "${1:-}" ]; then
  # Als het script een argument kreeg (van protocol-handler of cli), gebruik dat direct
  URL="$1"
else
  # Anders: normale interactieve modus
  CLIP="$(get_clipboard_raw)"
  MENU_ITEMS=()
  if printf '%s' "$CLIP" | is_url; then
    MENU_ITEMS+=("Gebruik clipboard-URL: $CLIP")
  fi
  MENU_ITEMS+=("Typ URL handmatig")

  CHOICE="$(printf '%s\n' "${MENU_ITEMS[@]}" | wofi_pick "$PROMPT_URL" || true)"
  [ -n "${CHOICE:-}" ] || { echo "Geannuleerd."; exit 130; }

  if [[ "$CHOICE" == *clipboard* ]]; then
    URL="$CLIP"
  else
    URL="$(printf '' | wofi_pick 'Typ URL (http/https)' || true)"
    [ -n "${URL:-}" ] || { echo "Geannuleerd."; exit 130; }
  fi
fi

printf '%s' "$URL" | is_url || die "Ongeldige URL (moet met http/https beginnen)."

# ----- 2) Directories verzamelen -----
collect_dirs_fd() {
  local root="$1" bin="$FD_BIN"
  command -v "$bin" >/dev/null 2>&1 || bin="fdfind"
  command -v "$bin" >/dev/null 2>&1 || return 1
  if [ "$HIDE_DOTDIRS" = true ]; then
    "$bin" -t d . "$root" 2>/dev/null
  else
    "$bin" -t d -H . "$root" 2>/dev/null
  fi
}
collect_dirs_find() {
  local root="$1"
  if [ "$HIDE_DOTDIRS" = true ]; then
    find "$root" -type d -not -path '*/\.*' 2>/dev/null
  else
    find "$root" -type d 2>/dev/null
  fi
}

declare -a CANDS=()
mapfile -t CANDS < <(sed '/^$/d' "$MRU_FILE" 2>/dev/null || true)
for r in "${ROOTS[@]}"; do
  [ -d "$r" ] && CANDS+=("$r")
  if mapfile -t TMP < <(collect_dirs_fd "$r"); then
    CANDS+=("${TMP[@]}")
  else
    mapfile -t TMP < <(collect_dirs_find "$r")
    CANDS+=("${TMP[@]}")
  fi
done
mapfile -t CANDS < <(printf '%s\n' "${CANDS[@]}" | awk 'NF' | sed 's#//*#/#g' | awk '!seen[$0]++')

CHOICE_DIR="$(printf '%s\n' "${CANDS[@]}" | wofi_pick "$PROMPT_DIR" || true)"
[ -n "${CHOICE_DIR:-}" ] || { echo "Geannuleerd."; exit 130; }
[ -d "$CHOICE_DIR" ] || mkdir -p "$CHOICE_DIR"
[ -w "$CHOICE_DIR" ] || die "Geen schrijfrechten in: $CHOICE_DIR"

# ----- 3) Flags togglen (geen default) -----
OPEN=0
SNAP=0
READ=0
FORMATS=("org")

format_option() {
  local fmt="$1"
  for chosen in "${FORMATS[@]}"; do
    if [ "$chosen" = "$fmt" ]; then
      printf '[x] %s' "$fmt"
      return
    fi
  done
  printf '[ ] %s' "$fmt"
}

toggle_format() {
  local fmt="$1" new=()
  local found=0
  for chosen in "${FORMATS[@]}"; do
    if [ "$chosen" = "$fmt" ]; then
      found=1
      continue
    fi
    new+=("$chosen")
  done
  if [ $found -eq 0 ]; then
    new+=("$fmt")
  fi
  FORMATS=("${new[@]}")
}

while :; do
  # Toon huidige status
  SEL="$(printf '%s\n' \
      'Klaar' \
      "$( [ $OPEN -eq 1 ] && echo '[x]' || echo '[ ]' ) --open" \
      "$( [ $SNAP -eq 1 ] && echo '[x]' || echo '[ ]' ) --snapshot" \
      "$( [ $READ -eq 1 ] && echo '[x]' || echo '[ ]' ) --readability" \
      '---' \
      "$(format_option org)" \
      "$(format_option markdown)" \
      "$(format_option typst)" \
      "$(format_option latex)" \
      "$(format_option docx)" \
    | wofi_pick "$PROMPT_FLAGS" || true)"
  case "${SEL:-}" in
    "[x] --open"|"[ ] --open")         OPEN=$((1-OPEN)) ;;
    "[x] --snapshot"|"[ ] --snapshot")  SNAP=$((1-SNAP)) ;;
    "[x] --readability"|"[ ] --readability") READ=$((1-READ)) ;;
    "[x] org"|"[ ] org")               toggle_format "org" ;;
    "[x] markdown"|"[ ] markdown")     toggle_format "markdown" ;;
    "[x] typst"|"[ ] typst")           toggle_format "typst" ;;
    "[x] latex"|"[ ] latex")           toggle_format "latex" ;;
    "[x] docx"|"[ ] docx")             toggle_format "docx" ;;
    ""|"Klaar")                         break ;;
    "---")                              : ;;
    *)                                  break ;;
  esac
done

# Als gebruiker alle formaten uitzet: val terug op org
if [ ${#FORMATS[@]} -eq 0 ]; then
  FORMATS=("org")
fi

EXTRA_FLAGS_BASE=()
[ $OPEN -eq 1 ] && EXTRA_FLAGS_BASE+=(--open)
[ $SNAP -eq 1 ] && EXTRA_FLAGS_BASE+=(--snapshot)
[ $READ -eq 1 ] && EXTRA_FLAGS_BASE+=(--readability)

declare -a OUTPUTS=()

# ----- 4) url2org draaien per gekozen formaat -----
for FMT in "${FORMATS[@]}"; do
  EXTRA_FLAGS=("${EXTRA_FLAGS_BASE[@]}")
  EXTRA_FLAGS+=(--format "$FMT")

  if "$URL2ORG_BIN" --help 2>/dev/null | grep -q -- '--dir'; then
    OUT="$("$URL2ORG_BIN" "$URL" --dir "$CHOICE_DIR" "${EXTRA_FLAGS[@]}")" || die "url2org faalde"
    OUTPUTS+=("$OUT")
    echo "$OUT"
  else
    CREATED="$("$URL2ORG_BIN" "$URL" "${EXTRA_FLAGS[@]}")" || die "url2org faalde"
    if [ -n "${CREATED:-}" ] && [ -f "$CREATED" ]; then
      BASENAME="$(basename -- "$CREATED")"
      mv -f -- "$CREATED" "$CHOICE_DIR"/
      OUT="$CHOICE_DIR/$BASENAME"
      OUTPUTS+=("$OUT")
      echo "Verplaatst naar: $CHOICE_DIR ($BASENAME)"
    fi
  fi
done

# Desktopnotificatie bij succes (optioneel)
if command -v notify-send >/dev/null 2>&1; then
  if [ ${#OUTPUTS[@]} -gt 0 ]; then
    if [ ${#OUTPUTS[@]} -eq 1 ]; then
      notify-send "url2org" "Opgeslagen: $(basename -- "${OUTPUTS[0]}")" || true
    else
      last="${OUTPUTS[${#OUTPUTS[@]}-1]}"
      notify-send "url2org" "Opgeslagen ${#OUTPUTS[@]} bestanden (laatste: $(basename -- "$last"))" || true
    fi
  fi
fi

# MRU bijwerken (prepend, dedup, limit)
printf '%s\n' "$CHOICE_DIR" | cat - "$MRU_FILE" | awk 'NF' | awk '!seen[$0]++' | head -n 200 > "$MRU_FILE"
