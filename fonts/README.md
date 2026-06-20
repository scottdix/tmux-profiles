# Fonts

The powerline status bar uses U+E0B0 / U+E0B2 separator glyphs, which only the
patched **Nerd Font** build of JetBrains Mono draws. Standardize every machine
on this exact font name:

```
JetBrainsMono Nerd Font Mono
```

## Install

```sh
./install-fonts.sh
```

It copies the weights in [`ttf/`](ttf/) to your user font directory
(`~/Library/Fonts` on macOS, `~/.local/share/fonts` on Linux). If `ttf/` is
missing it downloads them from the official nerd-fonts release instead.

Then set your terminal's font to **JetBrainsMono Nerd Font Mono**. In iTerm2
also enable *Settings → Profiles → Text → Use built-in Powerline glyphs* as a
belt-and-suspenders fallback.

## What's vendored & why it's OK to redistribute

`ttf/` holds four weights of *JetBrainsMono Nerd Font Mono* (Regular, Bold,
Italic, BoldItalic), patched from JetBrains Mono v2.304 by Nerd Fonts v3.2.1.

Both upstreams ship under the **SIL Open Font License 1.1** (see [`OFL.txt`](OFL.txt)),
which expressly permits bundling and redistribution with software. The "Mono"
variant keeps every glyph single-width so columns never drift.
