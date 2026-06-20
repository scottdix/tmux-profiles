#!/usr/bin/env bash
# vms.sh — running guest/VM count as "N VMs", via the `qm` CLI. Reports 0 when
# `qm` isn't present, so the segment still renders harmlessly off-host. Content only.
if command -v qm >/dev/null 2>&1; then
  n="$(qm list 2>/dev/null | awk 'NR>1 && $3=="running"' | wc -l | tr -d ' ')"
else
  n=0
fi
printf '%s VMs' "${n:-0}"
