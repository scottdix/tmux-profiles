#!/usr/bin/env bash
# map.sh — manage private session-name → accent maps (schemes/*.local.scheme).
#
#   ./map.sh <name> <color> [--order N]   create or update a map
#   ./map.sh --list                       show current local maps
#   ./map.sh --remove <name>              delete a map
#   ./map.sh ... --no-deploy              just write the file; skip rebuild/install
#
#   <color>   a tracked palette name (run --list to see them) or a raw #rrggbb.
#   --order   tie-break when globs overlap; LOWEST order wins (default 40).
#
# Real session/project names belong ONLY in schemes/*.local.scheme, which is
# gitignored and never published. This script writes those files; it never
# touches the tracked color-name schemes. See CLAUDE.md.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMES_DIR="$ROOT/schemes"

is_local() { case "$1" in *.local.scheme) return 0 ;; *) return 1 ;; esac; }

# Print "  label    #hex" for every tracked (non-local) palette scheme.
list_palette() {
  echo "palette (from tracked schemes):"
  for f in "$SCHEMES_DIR"/*.scheme; do
    [ -e "$f" ] || continue; is_local "$f" && continue
    ( unset GLOB ACCENT LABEL ORDER; . "$f"
      printf '  %-8s %s\n' "${LABEL:-${GLOB:-?}}" "${ACCENT:-?}" )
  done
  :
}

# Resolve a palette name to its hex by sourcing the matching tracked scheme.
# Accumulate the match and emit it once; returns success regardless of whether a
# match was found (callers test the emptiness of the captured output). This must
# not end on a non-zero status: under `set -e` a failing command-substitution
# here would abort the assignment `hex="$(palette_hex ...)"`.
palette_hex() {  # $1 = palette name
  local f v hex=""
  for f in "$SCHEMES_DIR"/*.scheme; do
    [ -e "$f" ] || continue; is_local "$f" && continue
    v="$( unset GLOB ACCENT LABEL ORDER; . "$f"
      [ "${LABEL:-}" = "$1" ] && printf '%s' "${ACCENT:-}" )"
    [ -n "$v" ] && hex="$v"
  done
  printf '%s' "$hex"
}

list_maps() {
  local found=0
  for f in "$SCHEMES_DIR"/*.local.scheme; do
    [ -e "$f" ] || continue; found=1
    ( unset GLOB ACCENT LABEL ORDER; . "$f"
      printf '  %-16s %-10s order=%s  (%s)\n' \
        "${LABEL:-?}" "${ACCENT:-?}" "${ORDER:-?}" "$(basename "$f")" )
  done
  [ "$found" = 1 ] || echo "  (no local maps yet)"
  :
}

# Lowercase + keep [a-z0-9_-] for a safe, stable filename slug.
slug() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_-' '-' | sed 's/^-*//; s/-*$//'; }

deploy() {
  # Rebuild + install, preserving the widget/scroll-lines from the last build.
  local args=() prev="$ROOT/build/tmux.conf" w s
  if [ -f "$prev" ]; then
    w="$(sed -n 's/^# widget=\([^ ]*\).*/\1/p' "$prev" | head -1)"
    s="$(sed -n 's/.*scroll-lines=\([^ ]*\).*/\1/p' "$prev" | head -1)"
    [ -n "$w" ] && args+=(--widget "$w")
    [ -n "$s" ] && args+=(--scroll-lines "$s")
  fi
  "$ROOT/install.sh" --no-font "${args[@]}"
}

# ── Args ─────────────────────────────────────────────────────────────────────
NAME=""; COLOR=""; ORDER=40; ACTION="set"; DEPLOY=1
while [ $# -gt 0 ]; do
  case "$1" in
    --list)       ACTION="list"; shift ;;
    --remove)     ACTION="remove"; NAME="${2:?--remove needs a name}"; shift 2 ;;
    --order)      ORDER="${2:?--order needs a value}"; shift 2 ;;
    --order=*)    ORDER="${1#*=}"; shift ;;
    --no-deploy)  DEPLOY=0; shift ;;
    -h|--help)    grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)           echo "map.sh: unknown flag: $1" >&2; exit 2 ;;
    *)
      if [ -z "$NAME" ]; then NAME="$1"
      elif [ -z "$COLOR" ]; then COLOR="$1"
      else echo "map.sh: unexpected argument: $1" >&2; exit 2; fi
      shift ;;
  esac
done

case "$ACTION" in
  list)
    list_palette; echo; echo "local maps:"; list_maps; exit 0 ;;
  remove)
    f="$SCHEMES_DIR/$(slug "$NAME").local.scheme"
    if [ -e "$f" ]; then rm -f "$f"; echo "removed $(basename "$f")"
    else echo "map.sh: no map for '$NAME' ($f)" >&2; exit 1; fi
    [ "$DEPLOY" = 1 ] && deploy
    exit 0 ;;
esac

# ── Create / update ──────────────────────────────────────────────────────────
[ -n "$NAME" ]  || { echo "map.sh: need a session name" >&2; echo; list_palette; exit 2; }
[ -n "$COLOR" ] || { echo "map.sh: need a color for '$NAME'" >&2; echo; list_palette; exit 2; }

case "$ORDER" in ''|*[!0-9]*) echo "map.sh: --order must be an integer" >&2; exit 2 ;; esac

# Resolve the color: raw #hex passes through; otherwise look it up by name.
if printf '%s' "$COLOR" | grep -Eq '^#[0-9A-Fa-f]{6}$'; then
  hex="$COLOR"
else
  hex="$(palette_hex "$COLOR")"
  [ -n "$hex" ] || { echo "map.sh: unknown color '$COLOR'" >&2; echo; list_palette; exit 2; }
fi

slug="$(slug "$NAME")"
[ -n "$slug" ] || { echo "map.sh: '$NAME' has no usable filename characters" >&2; exit 2; }
out="$SCHEMES_DIR/$slug.local.scheme"

verb="created"; [ -e "$out" ] && verb="updated"
cat > "$out" <<EOF
# Private name→color map — gitignored (schemes/*.local.scheme), never published.
# Written by map.sh. Real session names live ONLY in files like this. See CLAUDE.md.
GLOB="*$NAME*"
ACCENT="$hex"
LABEL="$NAME"
ORDER=$ORDER
EOF
echo "$verb $out  ($NAME → $hex, order=$ORDER)"

[ "$DEPLOY" = 1 ] && deploy
exit 0
