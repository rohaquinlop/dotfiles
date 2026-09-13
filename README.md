# Dotfiles

Personal **CachyOS + niri** configuration for a ThinkPad X1 Carbon Gen 9.
The shell, editor, terminal and prompt configs are shared with a MacBook Pro.

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Fresh Install

```bash
git clone git@github.com:rohaquinlop/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
sudo pacman -S --needed $(cat packages.txt)
./install.sh
```

The installer:

- Backs up conflicting files to `~/.dotfiles-backup-<timestamp>/`
- Stows every user package with `stow --no-folding`
- Installs system files (Vial udev rules, keyd config, Limine `mkinitcpio` wrapper) with `sudo`

niri reloads its configuration automatically after the files change.

## Packages

| Package | Target | Description |
|---------|--------|-------------|
| `shell` | `~/` | zsh + bash: starship, zoxide, fzf, eza, git aliases, venv hook |
| `niri` | `~/.config/niri/` | Window manager config, output layout, helper scripts |
| `alacritty` | `~/.config/alacritty/` | Terminal (catppuccin theme, persistent font size) |
| `nvim` | `~/.config/nvim/` | Neovim (LazyVim) |
| `starship` | `~/.config/starship.toml` | Prompt (catppuccin mocha) |
| `btop` | `~/.config/btop/` | System monitor |
| `git` | `~/.config/git/` | Git configuration |
| `gh` | `~/.config/gh/` | GitHub CLI |
| `herdr` | `~/.config/herdr/` | Herdr terminal workspace manager |
| `config-misc` | `~/.config/` | fontconfig, GTK bookmarks, mimeapps, chromium flags, imv, obsidian, WirePlumber audio rules |
| `noctalia` | `~/.config/noctalia/` | Lock screen: flat dark background with the CachyOS mark, compact login box |

`lazygit` is installed but intentionally **not** stowed: its config can contain
credentials. Everything else is symlinked into the repo, so editing a config in
`~/.config` edits the tracked file.

## Key Bindings (niri)

Ported from the old Omarchy/Hyprland muscle memory:

| Keys | Action |
|------|--------|
| `Super+Return`, `Super+Q` | Alacritty |
| `Super+W` | Close window |
| `Super+Alt+Q` | Herdr |
| `Super+Shift+Return`, `Super+B`, `Super+Shift+B` | Chromium |
| `Super+Shift+Alt+B` | Chromium (private) |
| `Super+E`, `Super+Shift+F` | Nautilus |
| `Super+Shift+N` | Neovim in Alacritty |
| `Super+C` / `Super+V` / `Super+X` | Universal copy / paste / cut |
| `Super+Ctrl+V` | Clipboard history (Noctalia) |
| `Print`, `Super+Shift+S` | Screenshot (clipboard + `~/Pictures/Screenshots`) |
| `Super+Print` | Color picker |
| `Super+Shift+arrows` | Move window / column |
| `Super+1..9` / `Super+Shift+1..9` | Focus / move to workspace |
| `Super+Space` | Noctalia launcher |
| `Super+S` | Noctalia control center |
| `Super+Alt+L` | Lock screen |
| `Super+P` | Toggle laptop panel (see [Displays](#displays)) |
| `XF86MonBrightnessUp` / `Down` | Brightness of the current monitor |

### Universal copy/paste

`Super+C`, `Super+V` and `Super+X` inject the right shortcut into the focused
window with `wtype`: terminals get `Ctrl+Insert` / `Shift+Insert`, everything
else gets `Ctrl+C` / `Ctrl+V` / `Ctrl+X`. This reproduces Omarchy's universal
clipboard. The scripts live in `niri/.config/niri/scripts/` and detect terminals
by `app_id` from `niri msg --json focused-window`.

### Displays

`cfg/display.kdl` pins both outputs instead of letting niri guess, so the
arrangement survives replugging: the MSI MP275Q sits **above** the laptop, and
the laptop is centred under it.

| Output | Mode | Scale | Logical | Position |
|--------|------|-------|---------|----------|
| `eDP-1` (laptop) | 1920x1200@60 | 1.25 | 1536x960 | 512,1440 |
| `HDMI-A-1` (external) | 2560x1440@**100** | 1 | 2560x1440 | 0,0 |

The monitor's *preferred* mode is 60 Hz. It also does 100 Hz, and the direct
HDMI port carries that fine, so it is pinned explicitly — without the `mode`
line niri picks the preferred 60 Hz.

`Super+P` runs `scripts/niri-toggle-internal.sh`, which switches the laptop
panel off and on. niri cannot express "panel off while the monitor is plugged
in" in the config file, so it is a keybind instead. The script refuses to turn
off the last enabled output, so it cannot black out the screen when the monitor
is unplugged. `niri msg output` changes are temporary: any config reload brings
the panel back.

Audio does **not** follow the monitor. Plugging HDMI in used to move the default
sink to the monitor's built-in speakers, so
`config-misc/.config/wireplumber/wireplumber.conf.d/51-hdmi-sink-priority.conf`
drops every HDMI sink to `priority.session = 400`:

| Sink | Priority | When it wins |
|------|----------|--------------|
| Bluetooth (AirPods) | 1010 | whenever connected |
| Laptop analog | 1000 | fallback — the normal default |
| HDMI (monitor) | 400 | only if it is the last sink, or picked by hand |

Picking the monitor by hand still works: `wpctl set-default <sink id>`. Check
what the rule did with `wpctl inspect <sink id> | grep priority.session`.

Bluetooth caveat: restarting WirePlumber (`systemctl --user restart
wireplumber`) while Bluetooth headphones are connected drops their A2DP
transport, and they go silent even though PipeWire still feeds their sink node.
Reconnect them — `bluetoothctl disconnect <mac> && bluetoothctl connect <mac>` —
or log out and back in. Editing these rules needs the restart, so reconnect
afterwards.

### Monitor brightness (DDC/CI)

`/sys/class/backlight/` only has `intel_backlight`. The external monitor has no
backlight device, so sysfs cannot dim it; DDC/CI is the only channel. `ddcutil`
plus the `i2c-dev` module cover that — `i2c-dev` alone is not enough, because
without it there are no `/dev/i2c-*` devices to write to.

```bash
ls /sys/class/backlight/    # only intel_backlight — why the monitor is unreachable
ls /dev/i2c-*               # missing = i2c-dev is not loaded
sudo ddcutil detect         # expect the MP275Q on bus i2c-2, card1-HDMI-A-1
ddcutil getvcp 10           # 0x10 = brightness: current and max
ddcutil setvcp 10 60        # set brightness to 60 of 100
```

No `sudo` and no `i2c` group are needed after setup: the `ddcutil` package ships
`/usr/lib/udev/rules.d/60-ddcutil-i2c.rules`, which grants access with the
`uaccess` tag. Noctalia uses the same path, so the brightness keys drive
the current monitor.

If `ddcutil detect` finds nothing, turn DDC/CI on in the monitor's OSD menu —
MSI hides that switch under Settings.

### Brightness keys

Noctalia decides per monitor, and it ships `enable_ddcutil = false`. With that
default the keys answer `error: current output has no brightness control` while
the monitor is focused, because only the laptop panel has a kernel backlight.
The `[brightness]` section at the end of `noctalia/.config/noctalia/config.toml`
turns DDC on and names a backend per connector:

| Connector | Backend |
|-----------|---------|
| `eDP-1` | `backlight`, device `intel_backlight` |
| `HDMI-A-1` | `ddcutil` |

`minimum_brightness = 0.05` stops a slip of the keys from blacking a screen.
Verified: with the monitor focused `brightness-up` moves only the monitor
(50 → 55), with the laptop focused only the laptop — the other screen does not
move.

Three things to know:

- `noctalia msg config-reload` applies an edit without a restart.
- The Noctalia settings GUI writes `~/.local/state/noctalia/settings.toml`, and
  that file wins over the stowed config. If a brightness change seems ignored,
  look for a `[brightness]` block there first.
- If DDC picks the wrong bus, pin it per connector:
  `[brightness.monitor."HDMI-A-1"] ddc_bus = 2`.

## How It Works

Each package mirrors the target path under `~`:

```
~/.dotfiles/niri/.config/niri/cfg/keybinds.kdl  ->  ~/.config/niri/cfg/keybinds.kdl
~/.dotfiles/shell/.zshrc                        ->  ~/.zshrc
```

### Stow commands

```bash
cd ~/.dotfiles

# Stow / unstow a single package
stow --no-folding -t ~ nvim
stow -D -t ~ nvim

# Dry run (check for conflicts)
stow --no-folding -n -v -t ~ nvim
```

**Always pass `--no-folding`.** Without it stow symlinks whole directories
instead of individual files.

## Syncing with the MacBook

```bash
cd ~/.dotfiles && git pull
stow --no-folding -t ~ nvim   # re-stow when new plugin files appear
```

For Neovim run `:Lazy sync`, then check `:Mason` for `efm-langserver`.
`nvim --version` must be 0.11+.

On macOS, install the terminal fonts:

```bash
brew install --cask font-noto-sans-mono font-symbols-only-nerd-font
```

## Fonts

- **UI**: CachyOS defaults — Adwaita Sans in GTK apps, Noto Sans for generic
  `sans-serif` requests. There are no user fontconfig family overrides.
- **Terminal**: Noto Sans Mono on both machines. On Linux, fontconfig
  redirects the family to the patched **NotoSansM Nerd Font Mono**
  (`ttf-noto-nerd`) via
  `config-misc/.config/fontconfig/conf.d/50-noto-nerd.conf`, so text keeps
  Noto Sans Mono letterforms while starship/nvim/btop glyphs come from the
  same font. Plain Noto Sans Mono has no Nerd Font glyphs, and alacritty's
  per-glyph fallback mis-renders the powerline caps.
- **Linux packages**: `ttf-noto-nerd` for the patched font; Noto Sans Mono
  itself ships with CachyOS (`noto-fonts`, pulled in by
  `cachyos-niri-noctalia`).

## Theme: Akane

The desktop palette is **Akane** (茜) from
[Grenish/omarchy-akane-theme](https://github.com/Grenish/omarchy-akane-theme) —
dusk navy, vermillion torii, sunset gold. That repo is an Omarchy theme, so only
its **colours and wallpapers** are used here; nothing from the Omarchy tooling
is installed.

| Surface | How it carries the palette |
|---------|----------------------------|
| Noctalia (bar, panels, lock screen) | `noctalia/.config/noctalia/palettes/akane.json`, selected with `noctalia msg color-scheme-set custom akane` (writes `settings.toml`, which wins) |
| Alacritty | `alacritty/.config/alacritty/akane.toml`, imported by `alacritty.toml`. The previous Catppuccin palette stays in `theme.toml` |
| btop | `btop/.config/btop/themes/akane.theme`, `color_theme = "akane"` |
| starship | `[palettes.akane]` in `starship.toml`; the Catppuccin palettes stay below it |
| niri | focus ring gradient `#e15a48 → #f0b45a` in `cfg/layout.kdl` |
| Neovim | catppuccin `color_overrides` in `lua/plugins/theme.lua`, so LazyVim keeps its structure |
| Login + lock screen | wallpaper background (as in the theme's own lock screen) with the white mark; greeter colours come from the theme's `hyprlock.conf`: outline `#e15a48`, dots `#f0c4a8`, failure `#d6453d` |
| Wallpapers | `~/Pictures/Wallpapers/akane/` (8 images, not tracked in git) |

Names differ per app, so the palette is mapped: `mauve`/`mPrimary`/accent →
`#e15a48`, `peach`/`mSecondary` → `#f0b45a`, `teal`/`mTertiary` → `#4a9bb0`,
`base`/`mSurface` → `#12101c`, `text`/`mOnSurface` → `#f0c4a8`. Regenerate the
palette JSON and the two app palettes from one place if you change colours —
they are three copies of the same list today.

The SDDM greeter takes its colours from the theme's `hyprlock.conf` variables
directly (`$color`, `$outer_color`, `$font_color`), so the login screen and the
lock screen agree. Its field fill is `$inner_color`, the background colour, so
the box stays transparent; on a failed login it fills faintly and turns
`#d6453d`, because the accent is vermillion already.

Switching back to Catppuccin: set `palette = 'catppuccin_mocha'` in
`starship.toml`, point `general.import` in `alacritty.toml` at `theme.toml`, set
btop's `color_theme = "catppuccin"`, drop the `focus-ring` block in
`cfg/layout.kdl`, and run
`noctalia msg color-scheme-set community Oxocarbon`.

## Keeping Both Screens in Sync

The greeter cannot read your home directory (mode 700), and Noctalia's lock
screen has no widget for the mark, so both screens use a pre-rendered image.
One root-owned script builds both from the current Noctalia wallpaper:

```bash
sudo sddm-theme-sync     # force a rebuild by hand
```

| Output | Consumer |
|--------|----------|
| `/usr/share/sddm/themes/cachyos/background.jpg` | greeter (the mark is drawn over it by QML) |
| `~/.local/state/noctalia/lock-background.jpg` | lock screen (`wallpaper =` in the Noctalia config), mark baked in |

`/etc/systemd/system/sddm-theme-sync.path` watches Noctalia's `settings.toml`, so
choosing another wallpaper rebuilds both images automatically. The script keeps a
stamp and exits early when the outputs are already current.

Neither image is tracked in git: they change with the wallpaper, and tracking
them would leave the repo dirty after every change. Only the generators
(`system/sddm/make-wordmark.sh`, `system/local/bin/sddm-theme-sync`) and the
theme's QML are tracked.

## Login Screen (SDDM)

The greeter is a minimal SDDM theme in `system/sddm/`, copied to
`/usr/share/sddm/themes/cachyos` by `install.sh`: the distro's own boot
wordmark, a padlock and one password box. No user list, no session picker, no
clock, no username label — the layout is Omarchy's (their theme, MIT, is the
base for the QML), and the artwork is CachyOS's own, so the login screen
matches what boots.

| File | Installed to |
|------|--------------|
| `system/sddm/themes/cachyos/` | `/usr/share/sddm/themes/cachyos/` |
| `system/sddm/sddm.conf.d/10-theme.conf` | `/etc/sddm.conf.d/10-theme.conf` (selects the theme + cursor) |

Preview it without logging out (the repo copy, no sudo needed):

```bash
sddm-greeter-qt6 --test-mode --theme system/sddm/themes/cachyos
```

**Mark.** The distro's own wordmark is a 243x66 bitmap (the Plymouth boot
display) — too coarse and too teal over a photo. The login mark is built
instead from two crisp sources by `system/sddm/make-wordmark.sh`:

- the distro's **vector** emblem, `/usr/share/icons/cachyos.svg`, rasterised and
  recoloured to white through its alpha channel;
- `CACHYOS` set in Noto Sans Mono Condensed Black — the heavy cut of the
  terminal font — in white.

Result: `wordmark.png`, 773x145, white, so it reads over any wallpaper and stays
sharp at any scale. Change the name with `WD_TEXT=... ./system/sddm/make-wordmark.sh`.

**Background.** Like the Akane theme's own lock screen, both screens sit on the
wallpaper — see *Keeping Both Screens in Sync* below. `Main.qml` draws the mark
over `themes/cachyos/background.jpg`, which the sync script writes at install
time; the file is generated, so it is not tracked in git.

**Colours.** Everything comes from the theme's own `hyprlock.conf` variables:
`$color` `#12101c` (background), `$outer_color` `#e15a48` (padlock and field
outline), `$font_color` `#f0c4a8` (the dots), `$inner_color` `#12101c` at 80%
(the field fill). Failures turn the field and padlock `#d6453d` and fill the
field faintly, since the accent is vermillion already.

`Main.qml` sizes everything by `Screen.height / 1200`, so the greeter renders at
the same physical size whatever scale factor SDDM applies. On this 1920x1200
panel: 773x145 mark, 26px gap, 35x40 padlock, 240x40 password box.

**Centring.** The mark and the password box share the panel's centre line. The
padlock sits in a 35px gutter to the left of the box and an empty spacer of the
same width balances the row on the right, so the box is not pushed off centre by
its own padlock. Measured on a 1920x1200 render: box 840..1080 (centre 960),
mark centred on 960, whole block centred vertically.

To go back to the stock greeter: `sudo rm /etc/sddm.conf.d/10-theme.conf`.

## Lock Screen (Noctalia)

Closing the lid suspends the machine, and waking shows the **Noctalia** lock
screen, not SDDM. Noctalia already locks before sleep (`lock_before_suspend`),
so no systemd sleep hook is needed — `systemd-inhibit --list` shows
`noctalia … sleep "Lock before sleep"`.

The `noctalia` package makes that lock screen match the login screen:

- `config.toml` — `[lockscreen]` disables desktop capture, blur and tint and
  points `wallpaper` at the asset below. The login box widget runs
  `layout = "compact"` with no card background and no media/weather/session
  extras.
- `wallpaper` points at `~/.local/state/noctalia/lock-background.jpg` — the
  current wallpaper darkened 55%, with the white mark centred. It is baked into
  the image rather than added as a widget, so it cannot fail to draw, and
  `sddm-theme-sync` rebuilds it whenever the wallpaper changes.

**Noctalia's `settings.toml` wins over this file.** Anything changed in the GUI —
including the lock screen widget editor
(`noctalia msg lockscreen-widgets-edit`) — is written to
`~/.local/state/noctalia/settings.toml` and overrides `config.toml`. If a value
here stops taking effect, delete the matching block from that file and run
`noctalia msg config-reload`. `noctalia config validate` checks the TOML and
`noctalia config export` prints the effective configuration.

The lock screen input field keeps the Noctalia palette (community "Oxocarbon");
only the background, the mark and the panel shape come from this package.

## System-Level Files

Copied with `sudo` by `install.sh` (not symlinked):

- `/etc/udev/rules.d/59-vial.rules`, `/etc/udev/rules.d/99-vial.rules` — Vial keyboard access
- `/etc/modules-load.d/i2c-dev.conf` — loads `i2c-dev` so `ddcutil` can set the external monitor's brightness
- `/etc/keyd/default.conf` — Caps Lock → Backspace
- `/usr/local/bin/mkinitcpio` — warns when Limine boot entries need `limine-mkinitcpio`
- `/usr/share/sddm/themes/cachyos/` + `/etc/sddm.conf.d/10-theme.conf` — login screen (see above)
- `/usr/local/bin/sddm-theme-sync` + `/etc/systemd/system/sddm-theme-sync.{path,service}` — keeps both screens on the current wallpaper

## Notes

- `herdr` binary lives in `~/.local/bin` and `pi` comes from bun; neither is
  tracked here (reinstall them after a disk wipe).
