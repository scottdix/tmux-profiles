#!/usr/bin/env bash
# install.sh — build the config and deploy it to this machine.
#
#   ./install.sh [--widget cpu|vms|none] [--scroll-lines N] [--no-font]
#                [--map NAME=COLOR ...]
#
#   --map NAME=COLOR   define a private session→accent map before building
#                      (delegates to ./map.sh; repeatable). COLOR is a palette
#                      name or #rrggbb. Real names land only in the gitignored
#                      schemes/*.local.scheme. Manage these later with ./map.sh.
#
#   cpu   busiest process %     (default; good for dev laptops/servers)
#   vms   running VM count      (hosts with the `qm` CLI)
#   none  load + clock only
#
#   --scroll-lines N   lines per mouse-wheel notch in copy-mode (default 1).
#                      Tune per host — lower on low-latency links that feel fast.
#
# Backs up any existing real ~/.tmux.conf, copies the helper scripts to
# ~/.tmux/, installs the rendered config, and reloads a running tmux server.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIDGET="cpu"; DO_FONT=1; SCROLL_LINES=""; MAPS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --widget)         WIDGET="${2:?--widget needs a value}"; shift 2 ;;
    --widget=*)       WIDGET="${1#*=}"; shift ;;
    --scroll-lines)   SCROLL_LINES="${2:?--scroll-lines needs a value}"; shift 2 ;;
    --scroll-lines=*) SCROLL_LINES="${1#*=}"; shift ;;
    --map)            MAPS+=("${2:?--map needs NAME=COLOR}"); shift 2 ;;
    --map=*)          MAPS+=("${1#*=}"); shift ;;
    --no-font)        DO_FONT=0; shift ;;
    -h|--help)        grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "install.sh: unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Define any requested session→accent maps first (writes gitignored local
# schemes; --no-deploy so we build/deploy once, below — not per map).
for m in ${MAPS[@]+"${MAPS[@]}"}; do
  name="${m%%=*}"; color="${m#*=}"
  [ -n "$name" ] && [ "$name" != "$m" ] && [ -n "$color" ] \
    || { echo "install.sh: --map needs NAME=COLOR (got '$m')" >&2; exit 2; }
  "$ROOT/map.sh" --no-deploy "$name" "$color"
done

build_args="--widget $WIDGET"
[ -n "$SCROLL_LINES" ] && build_args="$build_args --scroll-lines $SCROLL_LINES"
# shellcheck disable=SC2086
"$ROOT/build.sh" $build_args

ts="$(date +%Y%m%d-%H%M%S)"
# Back up only when the live config actually differs from what we're about to
# install — otherwise repeated runs (e.g. via map.sh) would spew .bak files.
if [ -e "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ] \
   && ! cmp -s "$ROOT/build/tmux.conf" "$HOME/.tmux.conf"; then
  cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak-$ts"
  echo "backed up existing ~/.tmux.conf -> ~/.tmux.conf.bak-$ts"
fi

# ~/.tmux/bin is fully managed: rebuilt to exactly match common/bin every run,
# so the deployed state is determined by the repo, not by what was here before.
# (Anything else under ~/.tmux/ — plugins, your own scripts — is left alone.)
rm -rf "$HOME/.tmux/bin"
mkdir -p "$HOME/.tmux/bin"
cp "$ROOT"/common/bin/*.sh "$HOME/.tmux/bin/"
chmod +x "$HOME"/.tmux/bin/*.sh
rm -f "$HOME/.tmux/load.sh"   # sweep away the legacy flat-layout renderer
cp "$ROOT/build/tmux.conf" "$HOME/.tmux.conf"
echo "installed ~/.tmux.conf and refreshed ~/.tmux/bin/{lib,load,cpu,vms}.sh"

# Reload a running server even if we're not attached to it (a detached session
# started under an older config still picks up the change).
if command -v tmux >/dev/null 2>&1 && tmux has-session 2>/dev/null; then
  tmux source-file "$HOME/.tmux.conf" && echo "reloaded the running tmux server"
fi

if [ "$DO_FONT" = 1 ]; then
  echo
  echo "Font: this bar needs 'JetBrainsMono Nerd Font Mono'."
  echo "  install it with:  $ROOT/fonts/install-fonts.sh"
  echo "  then set your terminal font to: JetBrainsMono Nerd Font Mono"
fi
