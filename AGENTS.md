# AGENTS.md

Dotfiles repo for CachyOS + niri (ThinkPad X1 Carbon Gen 9). Managed with GNU
Stow. Shell, editor, terminal and prompt configs are shared with a MacBook Pro.

## Architecture

Each stow package mirrors the target path under `~`:

```
niri/.config/niri/cfg/keybinds.kdl  →  ~/.config/niri/cfg/keybinds.kdl
shell/.zshrc                        →  ~/.zshrc
```

Stowed packages: `shell alacritty nvim starship btop git gh herdr niri config-misc noctalia`.

Desktop palette: **Akane**, from the Omarchy theme
`github.com/Grenish/omarchy-akane-theme` — colours and wallpapers only, no
Omarchy tooling. It lives in three places that must be kept in sync: the Noctalia
palette JSON (`noctalia/.config/noctalia/palettes/akane.json`), the alacritty
theme (`alacritty/.config/alacritty/akane.toml`), and the starship + Neovim
catppuccin overrides. See the README table for the full mapping.

Non-stowed files (require `sudo cp`, handled by `install.sh`):
- `system/udev/rules.d/` → `/etc/udev/rules.d/`
- `system/keyd/` → `/etc/keyd/`
- `system/local/bin/` → `/usr/local/bin/`
- `system/sddm/themes/cachyos/` → `/usr/share/sddm/themes/cachyos/`
- `system/sddm/sddm.conf.d/` → `/etc/sddm.conf.d/`
- `system/systemd/` → `/etc/systemd/system/` (the wallpaper sync path unit)

## Critical Quirks

- **The login and lock screen backgrounds are generated, not tracked.**
  `/usr/local/bin/sddm-theme-sync` builds them from the current Noctalia
  wallpaper; `sddm-theme-sync.path` triggers it on wallpaper changes. Force a
  rebuild with `sudo sddm-theme-sync` after moving wallpaper files around.
- **Noctalia's `settings.toml` overrides `~/.config/noctalia/*.toml`.** GUI
  changes — including the lock screen widget editor — are written to
  `~/.local/state/noctalia/settings.toml` and win over the stowed config. Delete
  the matching block there, then `noctalia msg config-reload`. Use
  `noctalia config validate` and `noctalia config export` to check.
- **Always use `stow --no-folding`**. Without it stow creates directory symlinks
  instead of individual file symlinks.
- **The SDDM theme's sizes scale with `Screen.height / 1200`, not with a fixed
  pixel size**, so it stays put when SDDM applies its own HiDPI scale factor.
  Check edits with `sddm-greeter-qt6 --test-mode --theme <theme dir>` — that
  renders any copy in a window, so point it at the repo path. The installed
  greeter only ever reads `/usr/share/sddm/themes/`.
- **niri auto-reloads its config** when files change. Validate edits with
  `niri validate -c niri/.config/niri/config.kdl` (includes are resolved
  relative to the config file).
- **Universal copy/paste** (`Super+C/V/X`) uses `wtype` plus terminal detection
  from `niri msg --json focused-window` (see `niri/.config/niri/scripts/`).
  Do not replace it with plain `wl-copy`/`wtype` blindly: terminals need
  `Ctrl+Insert` / `Shift+Insert`, other apps `Ctrl+C` / `Ctrl+V`.
- **lazygit is intentionally not stowed** — its config can contain credentials.
  Do not add it back to the repo.
- **Deleting a file from a stowed package leaves a dangling symlink in `~`.**
  `stow` does not clean those up. Check with `find ~/.config -xtype l` and remove
  the ones pointing into this repo. (Chromium/Firefox `SingletonLock`-style
  broken links are normal runtime files.)
- **Terminal font is Noto Sans Mono** on both machines. On Linux, fontconfig
  redirects the family to the patched `NotoSansM Nerd Font Mono`
  (`ttf-noto-nerd`) via
  `config-misc/.config/fontconfig/conf.d/50-noto-nerd.conf`. Plain Noto Sans
  Mono plus alacritty's per-glyph fallback mis-renders the powerline caps, so
  do not remove that rule or the package. Alacritty only draws the powerline
  triangles (U+E0B0-E0B3) itself; the round caps (U+E0B4/E0B6) come from the
  font and are one pixel shorter than alacritty's cell, hence
  `font.offset.y = -2` + `font.glyph_offset.y = -1` in `alacritty.toml`
  (tuned for the default font size).
- The `system/local/bin/mkinitcpio` wrapper is a safety net for manual
  `mkinitcpio -P` runs; it calls the CachyOS-native `limine-mkinitcpio`.
- The CachyOS niri defaults live in `~/.config/niri/` and are tracked here after
  the first install; editing them directly edits the repo.

## Commands

```bash
# Full install (backs up conflicting files, stows, installs system files)
./install.sh

# Stow a single package
stow --no-folding -t ~ <package-name>

# Unstow a single package
stow -D -t ~ <package-name>

# Dry-run (check for conflicts)
stow --no-folding -n -v -t ~ <package-name>

# Validate niri config
niri validate -c niri/.config/niri/config.kdl

# Preview the SDDM login theme without rebooting
sddm-greeter-qt6 --test-mode --theme system/sddm/themes/cachyos
```

## Adding a New Package

```bash
mkdir -p new-pkg/.config/new-app
mv ~/.config/new-app/config new-pkg/.config/new-app/config
stow --no-folding -t ~ new-pkg
```

Add the package to `STOW_PACKAGES` in `install.sh` and to the README table.

## Sensitive Files (Never Commit)

- `gh/.config/gh/hosts.yml` — GitHub auth token
- `lazygit/.config/lazygit/config.yml` — can contain credentials (gitignored)
- SSH keys (never live inside this repo)

`nvim/.config/nvim/lazy-lock.json` is generated by `:Lazy sync` and gitignored.

## Commit Conventions

Conventional Commits format. Recent history uses lowercase descriptions without
scope for broad changes:

```
refactor: migrate dotfiles to GNU Stow
niri: port Omarchy keybindings
fix: restore universal clipboard after wtype update
```
