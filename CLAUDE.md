# CLAUDE.md — tmux-profiles

Powerline tmux status bar with per-session accent colors, plus a top
pane-border strip. `build.sh` renders `common/tmux.conf.in` + `schemes/*.scheme`
into `build/tmux.conf`; `install.sh` deploys it to `~/.tmux.conf` and refreshes
`~/.tmux/bin/`.

## ⚠️ NEVER put real session/project names in tracked files

This is a hard rule. The published repo must contain **no** personal session or
project names (e.g. host names, client names, internal codenames). Anyone
reading the git history must not learn what you call your sessions.

- **Tracked schemes** (`schemes/*.scheme`) match **generic color-name globs
  only** — `*amber*`, `*cyan*`, `*green*`, `*blue*`. Never edit one to match a
  real session name.
- **Private name→color maps** go in `schemes/*.local.scheme`, which is
  **gitignored** (`schemes/*.local.scheme` in `.gitignore`) and picked up by
  `build.sh` because its glob `schemes/*.scheme` also matches `*.local.scheme`.
  This is the ONLY place a real session name may appear.
- Real names must also never leak into `common/tmux.conf.in`, `README.md`,
  comments, commit messages, or `CLAUDE.md` itself.

To color a session, use `map.sh` (it writes the gitignored local scheme for
you, validates the color against the palette, then rebuilds + reloads):

```sh
./map.sh <name> <color>     # e.g. ./map.sh myhost amber   (or a raw #rrggbb)
./map.sh --list             # show palette + current local maps
./map.sh --remove <name>    # delete a map
./map.sh ... --no-deploy    # just write the file, skip rebuild/install
```

Adding a profile later is the same one command — re-running a name updates its
color in place (idempotent). First-time setup can fold maps into the installer:
`./install.sh --map myhost=amber --map db=blue`. Either way the real name lands
ONLY in `schemes/<name>.local.scheme` (gitignored). Equivalent hand-written file:

```sh
GLOB="*myhost*"
ACCENT="#fabd2f"   # reuse a palette color; don't invent new ones
LABEL="myhost"
ORDER=40           # lowest ORDER wins on overlapping globs
```

Note: `install.sh` writes a backup `~/.tmux.conf.bak-*` only when the live
config actually changed; it WILL contain your live (name-bearing) config —
that's outside the repo and gitignored via `*.bak-*`.

## Build / deploy

```sh
./build.sh [--widget cpu|vms|none] [--scroll-lines N]   # render build/tmux.conf
./install.sh [--map NAME=COLOR ...]                     # deploy + refresh bin/
./map.sh <name> <color>                                 # add/update a session→accent map
tmux source-file ~/.tmux.conf                           # apply to a running server
```

`@@ACCENT@@` / `@@STATUS_RIGHT@@` / `@@SCROLL_LINES@@` in the template are
substituted by `build.sh`. The accent is a nested `#{?#{m:GLOB,#S},…}`
conditional generated from the scheme files; unknown sessions fall through to
neutral grey (`#928374`).

## Top strip (pane-border-status)

`common/tmux.conf.in` sets `pane-border-status top` + `pane-border-format` to
draw ` [#S] <cwd>` on each pane's top border. It rides the existing border line
(no added height); the active pane's border keeps its accent color via
`pane-active-border-style`. With one pane it reads as a top bar; with splits,
each pane is labeled.
