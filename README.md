# tmux-profiles

A versioned tmux setup that keeps the **bar's look** (per-session color schemes)
cleanly separate from the **bar's behavior** (layout, scrolling, system widgets),
and combines them into a deployable `~/.tmux.conf` on any machine.

It's a gruvbox powerline status bar where *only the accent color changes per
session* — picked from the session name (`#S`) by a substring match. Name a
session so it contains `amber`, `green`, `blue`, or `cyan` and it takes that
accent; anything unrecognized falls back to neutral grey.

```
[ amber-session ]   load 0.7   cpu 12%   9:41 AM     ← session name contains "amber"  → amber
[ api-green     ]   load 0.7   cpu 12%   9:41 AM     ← contains "green"               → green
[ db-blue       ]   …                                 ← contains "blue"                → blue
[ cyan-svc      ]   …                                 ← contains "cyan"                → cyan
[ whatever      ]   …                                 ← no match                       → grey
```

Same powerline shape and charcoal core everywhere; only the accent (the
`[session]` tag and the clock) moves. The look originates from a Claude Design
project.

## Quick start

```sh
git clone <this-repo> tmux-profiles && cd tmux-profiles
./install.sh                 # dev laptop/server: load · cpu% · clock  (default)
./install.sh --widget vms    # hosts with the `qm` CLI: load · running VMs · clock
./install.sh --widget none   # just load · clock
./install.sh --scroll-lines 2   # faster mouse-wheel scroll (default 1; tune per host)
./fonts/install-fonts.sh     # JetBrainsMono Nerd Font Mono (needed for the glyphs)
```

`install.sh` renders the config, backs up any existing `~/.tmux.conf`, then
rebuilds `~/.tmux/bin/` to exactly match the repo (a fully managed directory —
anything else under `~/.tmux/` is left untouched), and live-reloads a running
tmux server. Re-running it always lands the same state regardless of what was
there before.

## Layout — the display/config split

| Path | Layer | What lives here |
|------|-------|-----------------|
| `schemes/*.scheme` | **display** | One file per scheme: `GLOB`, `ACCENT`, `LABEL`, `ORDER`. This is the design surface. |
| `common/tmux.conf.in` | **config** | The whole bar + behavior, with `@@ACCENT@@` / `@@STATUS_RIGHT@@` / `@@SCROLL_LINES@@` placeholders. |
| `common/bin/*.sh` | **config** | `lib.sh` (shared palette) + `load.sh`, `cpu.sh`, `vms.sh` content renderers. |
| `build.sh` | glue | schemes/ + template → `build/tmux.conf`. |
| `install.sh` | glue | build + deploy to this machine. |
| `fonts/` | assets | JetBrainsMono Nerd Font Mono (OFL-1.1) + installer. |

Why the split:
1. **Schemes are version-controlled and independent of config.** Each scheme is
   four lines; touching one never risks the shared behavior.
2. **Adding a scheme and deploying elsewhere is trivial** — see below.

## Add a scheme

Drop a file in `schemes/` and rebuild — that's the whole workflow:

```sh
cat > schemes/pink.scheme <<'EOF'
# pink
GLOB="*pink*"
ACCENT="#d3869b"
LABEL="pink"
ORDER=15
EOF

./install.sh   # regenerates the accent expression and redeploys
```

`build.sh` compiles all schemes into one nested tmux conditional, lowest `ORDER`
checked first, unknown sessions falling through to neutral grey (`#928374`).
Matching is by **substring glob**, so `pink`, `pink-api`, and `eu-pink-1` all
resolve.

### Private / environment-specific schemes

The published schemes are keyed by **color** on purpose. If you want to map your
own real session or host names to a color on a given machine, drop a file named
`schemes/<whatever>.local.scheme` — those are gitignored and never published:

```sh
cat > schemes/mine.local.scheme <<'EOF'
GLOB="*myhost*"
ACCENT="#fabd2f"
LABEL="myhost"
ORDER=5
EOF
./install.sh
```

## How the accent works

`build.sh` turns `schemes/` into a single inlined expression (a `%hidden` var
can't be used here — tmux doesn't re-evaluate those inside format strings):

```tmux
#{?#{m:*cyan*,#S},#00cdcd,#{?#{m:*green*,#S},#3fb950,#{?#{m:*blue*,#S},#7aa2f7,#{?#{m:*amber*,#S},#fabd2f,#928374}}}}
```

The shared charcoal core (`#282828` bg, `#504945`/`#3c3836` panels, `#fb4934`
alert red, `#ebdbb2` fg) is identical in every scheme; alerts stay red
everywhere by design.

## Copy & scroll

- Mouse-wheel up enters copy-mode and scrolls; **`q`** exits straight back to the
  live prompt. Drag-select keeps the highlight in place (no auto-copy, no snap).
- `set-clipboard` is pinned **off** — tmux never touches the system clipboard, so
  no remote process can read it. For the system clipboard, copy natively: hold
  **⌥ Option** while drag-selecting, then **Cmd-C**. `y` copies into tmux's own
  buffer (paste with `prefix` + `]`).

## Requirements

- **tmux 3.3+** (`#{?...}` / `#{m:...}` formats)
- **JetBrainsMono Nerd Font Mono** for the `` `` separators — `fonts/install-fonts.sh`
- macOS or Linux — `load.sh` reads `sysctl` on macOS, `/proc` on Linux;
  `vms.sh` needs the `qm` CLI

## Editing

Edit `common/tmux.conf.in` or the scripts — **never** `build/tmux.conf` (generated)
or the deployed `~/.tmux.conf`. Re-run `./install.sh` to apply.
