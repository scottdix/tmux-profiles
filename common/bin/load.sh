#!/usr/bin/env bash
# load.sh — normalized 1-minute load average. Emits segment CONTENT only
# (no powerline separators — those are drawn by ~/.tmux.conf):
#   "load 0.7"      normal
#   "load 2.4 ⚠"    over 1.0  (the ⚠ stays red in every scheme)
#
# Normalized so 1.0 == every core busy. macOS via sysctl; Linux via /proc.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=/dev/null
[ -r "$DIR/lib.sh" ] && . "$DIR/lib.sh"
ALERT="${TM_ALERT:-#fb4934}"; FG="${TM_FG:-#ebdbb2}"

if [ -r /proc/loadavg ]; then
  ld="$(awk '{print $1}' /proc/loadavg)"
  cores="$(nproc 2>/dev/null || echo 1)"
else
  ld="$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')"
  cores="$(sysctl -n hw.ncpu 2>/dev/null || echo 1)"
fi
norm="$(awk -v l="${ld:-0}" -v c="${cores:-1}" 'BEGIN{printf "%.1f",(c>0)?l/c:l}')"
over="$(awk -v n="$norm" 'BEGIN{print (n>1)?1:0}')"

if [ "$over" = 1 ]; then
  printf 'load %s #[fg=%s,bold]⚠#[fg=%s,nobold]' "$norm" "$ALERT" "$FG"
else
  printf 'load %s' "$norm"
fi
