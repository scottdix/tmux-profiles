#!/usr/bin/env bash
# cpu.sh — busiest process as "name NN%", fixed width so the bar doesn't jitter
# on each refresh. Emits content only. Works on macOS and Linux (both BSD and
# GNU ps accept -Aceo pcpu,comm).
ps -Aceo pcpu,comm 2>/dev/null | tail -n +2 | sort -rn \
  | awk 'NR==1{printf "%-6.6s %2d%%", $2, $1}'
