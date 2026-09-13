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
Omarchy tooling. Almost every app follows Noctalia automatically through
Noctalia's template engine (`[theme.templates]` in
`noctalia/.config/noctalia/config.toml`): alacritty, starship, btop, GTK 3/4
(incl. the Qt palette via `QT_QPA_PLATFORMTHEME=gtk3`), niri, neovim, bat, fzf,
herdr, micro, pi, fastfetch, PrismLauncher and Chromium. Hand-written copies that
survive as offline fallbacks: `palettes/akane.json`, `alacritty/akane.toml`,
`btop/themes/akane.theme`, the starship `[palettes.akane]` table, the catppuccin
overrides in `nvim/lua/plugins/theme.lua`, the niri focus-ring gradient in
`cfg/layout.kdl`. See the README table for the full mapping.

Non-stowed files (require `sudo cp`, handled by `install.sh`):
- `system/udev/rules.d/` → `/etc/udev/rules.d/`
- `system/modules-load.d/` → `/etc/modules-load.d/` (loads `i2c-dev`, for
  monitor brightness — see the README)
- `system/keyd/` → `/etc/keyd/`
- `system/local/bin/` → `/usr/local/bin/`
- `system/sddm/themes/cachyos/` → `/usr/share/sddm/themes/cachyos/`
- `system/sddm/sddm.conf.d/` → `/etc/sddm.conf.d/`
- `system/systemd/` → `/etc/systemd/system/` (the wallpaper sync path unit)

## Critical Quirks

- **Noctalia can write into the repo through the stow symlinks.** The app
templates it applies (`noctalia msg templates-apply`, also run by `install.sh`)
own `~/.config/alacritty/themes/noctalia.toml`, a generated block in
`~/.config/starship.toml`, the `[theme.custom]` block in
`herdr/.config/herdr/config.toml` and the include in `alacritty.toml` — the last
three resolve into this repo, so a palette change leaves a `git diff`. Keep the
`noctalia` import last in `alacritty.toml` (later imports win; a missing file is
skipped, which is what makes `akane.toml` the fallback), and keep the
`include "noctalia.kdl"` last in `niri/config.kdl` for the same reason. Rendering
the palette outside Noctalia is impossible: `noctalia theme` needs an image or a
`--theme-json`.
- **Two templates need a one-time click in the app**: Chromium (`chrome://extensions`
  → Load unpacked → `~/.cache/noctalia/ungoogled-chromium/theme`) and
  PrismLauncher (Settings → Application theme → Matugen). lazygit's template is
  deliberately off: its config is untracked because it can hold credentials.
- **Neovim picks its colourscheme from the generated `lua/matugen.lua`.**
  `lua/plugins/theme.lua` checks for that file (written by the community neovim
  template, outside the repo) and hands LazyVim either a base16 function or the
  catppuccin name. `RRethy/base16-nvim` has no `colors/base16.vim`, so a
  `:colorscheme base16` string never works — keep it a function.
- **The login and lock screen backgrounds are generated, not tracked.**
  `/usr/local/bin/sddm-theme-sync` builds them from the current Noctalia
  wallpaper; `sddm-theme-sync.path` triggers it on wallpaper changes, and the
  same run regenerates the greeter palette
  (`/usr/share/sddm/themes/cachyos/NoctaliaColors.qml`) from Noctalia's gtk3
  template output. Force a rebuild with `sudo sddm-theme-sync` after moving
  wallpaper files around. The stamp covers the wallpaper and the palette, so a
  palette change alone still rewrites the scrimmed images. The repo copy of
  `NoctaliaColors.qml` is the Akane fallback — `Main.qml` reads `bgColor`,
  `accentColor`, `textColor`, `dangerColor` from it, and a `--test-mode` preview
  of the *repo* path renders those values. Preview the live palette by pointing
  test-mode at the installed theme instead. The greeter reads the palette when it
  starts, so a change appears at the next logout or reboot; restarting
  `sddm.service` is neither needed nor safe (it ends the session).
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
  `niri validate` (no `-c`): the deployed config is this repo's file through the
  stow symlink, and the `noctalia.kdl` include only resolves next to it. Pointing
  `-c` at the repo path fails — that generated file is not tracked.
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
- **Restarting WirePlumber silently kills connected Bluetooth audio.** The
  A2DP transport is dropped while the PipeWire sink node keeps running, so the
  headphones go mute with no error in any log. Reconnect them afterwards
  (`bluetoothctl disconnect <mac> && bluetoothctl connect <mac>`) or log out —
  this applies whenever the rules in `config-misc/.config/wireplumber/` change.
- **The internal speakers and the headphone jack are two mutually exclusive UCM
  profiles.** `sof-hda-dsp` exposes `Speaker` and `Headphones` as *conflicting*
  devices, and both `HiFi (…)` profiles carry the HDMI outputs. With a monitor
  plugged in, the empty-jack `Headphones` profile therefore wins on priority,
  its device is disabled, and every analog output is left muted — the laptop
  speakers go dead until the monitor is unplugged. `hda-analog-output.service`
  (`config-misc/.local/bin/hda-analog-output`) picks the profile from the jack
  state instead. Check with `systemctl --user status hda-analog-output` and
  `pactl list cards | grep 'Active Profile'`; a forced
  `pactl set-card-profile <card> 'HiFi (…)'` is corrected again within 10 s.
  Stopping the service restores the old broken behaviour.

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

# Audio: jack watcher for the analog UCM profile (see Critical Quirks)
systemctl --user status hda-analog-output
journalctl --user -u hda-analog-output

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
