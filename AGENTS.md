# AGENTS.md

Dotfiles repo for Omarchy (Hyprland) and CachyOS + niri on a ThinkPad X1 Carbon
Gen 9. Managed with GNU Stow. Shell, editor, terminal, prompt and Zed configs
are shared with a MacBook Pro.

## Architecture

Each stow package mirrors the target path under `~`:

```
niri/.config/niri/cfg/keybinds.kdl  →  ~/.config/niri/cfg/keybinds.kdl
zsh/.zshrc                          →  ~/.zshrc
hypr/.config/hypr/input.lua         →  ~/.config/hypr/input.lua
```

`install.sh` detects Omarchy (`omarchy` on PATH or `/usr/share/omarchy`) and
picks the stow set:

| Machine | Stowed packages |
|---------|-----------------|
| Omarchy | `zsh alacritty starship git zed hypr dsh` |
| CachyOS + niri, MacBook | `zsh bash alacritty nvim starship btop git gh herdr niri config-misc noctalia` |

Omarchy owns Hyprland defaults, the bar, the lock screen, btop, herdr and the
bash startup files; do not add them to the Omarchy set.

Desktop palette: **Akane**, from the Omarchy theme
`github.com/Grenish/omarchy-akane-theme` — colours and wallpapers only, no
Omarchy tooling. Almost every app follows Noctalia automatically through
Noctalia's template engine (`[theme.templates]` in
`noctalia/.config/noctalia/config.toml`): btop, GTK 3/4
(incl. the Qt palette via `QT_QPA_PLATFORMTHEME=gtk3`), niri, neovim, bat, fzf,
herdr, micro, pi, fastfetch, PrismLauncher and Chromium. On the niri machine,
Alacritty and starship are excluded on purpose and stay on Catppuccin Mocha;
on Omarchy, Alacritty follows the active Omarchy theme instead (see the README
Terminal section). Hand-written copies that
survive as offline fallbacks: `palettes/akane.json`, `btop/themes/akane.theme`,
the niri focus-ring gradient in `cfg/layout.kdl`. See the README table for the
full mapping.

Non-stowed files (require `sudo cp`, handled by `install.sh`). On Omarchy only
`system/keyd/` is installed; the rest is skipped because Omarchy manages it:
- `system/udev/rules.d/` → `/etc/udev/rules.d/`
- `system/modules-load.d/` → `/etc/modules-load.d/` (loads `i2c-dev`, for
  monitor brightness — see the README)
- `system/keyd/` → `/etc/keyd/`
- `system/local/bin/` → `/usr/local/bin/`
- `system/sddm/themes/cachyos/` → `/usr/share/sddm/themes/cachyos/`
- `system/sddm/sddm.conf.d/` → `/etc/sddm.conf.d/`
- `system/systemd/` → `/etc/systemd/system/` (the wallpaper sync path unit)

## Critical Quirks

- **The harness service owns port 3080.** `dsh-web.service` runs
  `~/.local/share/dsh/node_modules/.bin/dsh --profile web --no-open` from the
  local npm prefix. `install.sh` enables it but does not start it, because a
  manual `dsh web` may own the port. `~/.local/bin/dsh-web` starts it when
  needed, then opens the web app. The unit has a `ConditionPathExists` guard
  for the external npm install.
- **Caps Lock is Backspace through keyd.** `system/keyd/default.conf` maps it
  below the compositor, so the TTY and the desktop share one mapping.
  `install.sh` copies it to `/etc/keyd/` and enables `keyd.service` on both
  machines. `hypr/.config/hypr/input.lua` keeps `caps:backspace` as a Hyprland
  fallback for when keyd is stopped. Caps Lock compose sequences (fcitx5 +
  `~/.XCompose`) stop working.
- **`omazed` writes the Zed `theme` key through the stow symlink.** A theme
  change can therefore appear as a `git diff` in
  `zed/.config/zed/settings.json`. Keep `"theme": "Omazed"` so the sync keeps
  working; `my-zed-config` is the upstream source of the other keys.
- **Alacritty import order is deliberate.** `theme.toml` is the Catppuccin
  fallback, the Omarchy theme import overrides it, then `font.toml` and
  `local.toml`. Alacritty skips missing imports and later imports win, so the
  same file works on Omarchy, niri and the MacBook.
- **Noctalia can write into the repo through the stow symlinks.** The app
templates it applies (`noctalia msg templates-apply`, also run by `install.sh`)
own the `[theme.custom]` block in `herdr/.config/herdr/config.toml`, which
resolves into this repo, so a palette change leaves a `git diff`. Keep the
`include "noctalia.kdl"` last in `niri/config.kdl` (later includes win).
Alacritty and starship are deliberately not themed by Noctalia: keep their
templates out of `builtin_ids`. Rendering
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
- **Terminal font is per OS.** Do not put `[font]` in `alacritty.toml`: the
  importing file wins over its imports, so it would override the per-OS file.
  `install.sh` links `~/.config/alacritty/font.toml` to `fonts/linux.toml`
  (Noto Sans Mono) or `fonts/macos.toml` (JetBrainsMono Nerd Font). On Linux, fontconfig
  redirects the family to the patched `NotoSansM Nerd Font Mono`
  (`ttf-noto-nerd`) via
  `config-misc/.config/fontconfig/conf.d/50-noto-nerd.conf`. Plain Noto Sans
  Mono plus alacritty's per-glyph fallback mis-renders the powerline caps, so
  do not remove that rule or the package. Alacritty only draws the powerline
  triangles (U+E0B0-E0B3) itself; the round caps (U+E0B4/E0B6) come from the
  font and are a hair taller than the cell Alacritty builds, so the caps stick
  out of a prompt pill unless `font.offset.y` matches the cell to the cap
  height. Both offsets depend on the font size and the output scale, so
  `alacritty-font-size` computes them from the ttf-noto-nerd metrics and
  writes them into `~/.config/alacritty/local.toml` (imported last, so it wins
  over `fonts/linux.toml`). `alacritty-launch` runs `alacritty-font-size
  sync` before every terminal start, and the size keybinds recompute on every
  press. After changing the display scale by hand, run `alacritty-font-size
  sync`.
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

# DeepSeek Harness web UI (port 3080)
systemctl --user status dsh-web.service
journalctl --user -u dsh-web.service

# Omarchy: install packages, set the login shell, stow and install keyd
sudo pacman -S --needed $(tr '\n' ' ' < packages-omarchy.txt)
chsh -s /usr/bin/zsh
./install.sh
systemctl status keyd
keyd check
hyprctl getoption input:kb_options

# Validate niri config
niri validate -c niri/.config/niri/config.kdl

# Preview the SDDM login theme without rebooting
sddm-greeter-qt6 --test-mode --theme system/sddm/themes/cachyos

# Validate the login/lock screen palette chain (read-only, no sudo needed)
sddm-theme-sync --check
```

## Adding a New Package

```bash
mkdir -p new-pkg/.config/new-app
mv ~/.config/new-app/config new-pkg/.config/new-app/config
stow --no-folding -t ~ new-pkg
```

Add the package to the matching stow set in `install.sh` and to the README
table. Packages that only apply to the Omarchy machine go in the Omarchy set;
packages that only apply to the niri machine stay out of it.

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
