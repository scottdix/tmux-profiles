#!/usr/bin/env bash
# install-fonts.sh — install JetBrainsMono Nerd Font Mono for this user.
#
# Prefers the ttf/ vendored alongside this script (OFL-1.1, see OFL.txt);
# falls back to the official ryanoasis/nerd-fonts release if ttf/ is absent.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$(uname -s)" in
  Darwin) DEST="$HOME/Library/Fonts" ;;
  *)      DEST="$HOME/.local/share/fonts" ;;
esac
mkdir -p "$DEST"

if ls "$DIR"/ttf/JetBrainsMonoNerdFontMono-*.ttf >/dev/null 2>&1; then
  cp "$DIR"/ttf/JetBrainsMonoNerdFontMono-*.ttf "$DEST"/
  echo "installed vendored JetBrainsMono Nerd Font Mono -> $DEST"
else
  VER="v3.2.1"
  URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${VER}/JetBrainsMono.zip"
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  echo "ttf/ not vendored; downloading $URL ..."
  curl -fL "$URL" -o "$tmp/jbm.zip"
  unzip -o "$tmp/jbm.zip" 'JetBrainsMonoNerdFontMono-*.ttf' -d "$DEST"
  echo "installed JetBrainsMono Nerd Font Mono -> $DEST"
fi

case "$(uname -s)" in Linux) fc-cache -f "$DEST" >/dev/null 2>&1 || true ;; esac
echo "Now set your terminal font to: JetBrainsMono Nerd Font Mono"
