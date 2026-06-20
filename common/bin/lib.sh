#!/usr/bin/env bash
# lib.sh — shared gruvbox core palette for the ~/.tmux helper scripts.
#
# The charcoal core is identical in every scheme; only the per-session accent
# (set in ~/.tmux.conf, generated from schemes/) changes. Widgets that need a
# core color source this so the palette lives in exactly one place.
TM_CORE='#282828'    # charcoal status background
TM_LOADBG='#3c3836'  # load segment background
TM_PROCBG='#504945'  # panel grey / widget segment background
TM_ALERT='#fb4934'   # red — alerts, the same in every scheme
TM_FG='#ebdbb2'      # foreground text
TM_INK='#1d2021'     # near-black, text drawn on the accent
TM_GREY='#928374'    # neutral accent (unknown / unrecognized session)
