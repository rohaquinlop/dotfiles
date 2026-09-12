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
| `niri` | `~/.config/niri/` | Window manager config + universal clipboard scripts |
| `alacritty` | `~/.config/alacritty/` | Terminal (catppuccin theme, persistent font size) |
| `nvim` | `~/.config/nvim/` | Neovim (LazyVim) |
| `starship` | `~/.config/starship.toml` | Prompt (catppuccin mocha) |
| `btop` | `~/.config/btop/` | System monitor |
| `git` | `~/.config/git/` | Git configuration |
| `gh` | `~/.config/gh/` | GitHub CLI |
| `herdr` | `~/.config/herdr/` | Herdr terminal workspace manager |
| `config-misc` | `~/.config/` | fontconfig, GTK bookmarks, mimeapps, chromium flags, imv, obsidian |

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

### Universal copy/paste

`Super+C`, `Super+V` and `Super+X` inject the right shortcut into the focused
window with `wtype`: terminals get `Ctrl+Insert` / `Shift+Insert`, everything
else gets `Ctrl+C` / `Ctrl+V` / `Ctrl+X`. This reproduces Omarchy's universal
clipboard. The scripts live in `niri/.config/niri/scripts/` and detect terminals
by `app_id` from `niri msg --json focused-window`.

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
- **Terminal**: Noto Sans Mono on both machines. Nerd Font glyphs (starship,
  nvim devicons, btop) fall back to **Symbols Nerd Font Mono** through
  `config-misc/.config/fontconfig/conf.d/50-nerd-font-fallback.conf`.
- **Linux**: the symbols font comes from `ttf-nerd-fonts-symbols-mono`;
  Noto Sans Mono ships with CachyOS (`noto-fonts`, pulled in by
  `cachyos-niri-noctalia`).

## System-Level Files

Copied with `sudo` by `install.sh` (not symlinked):

- `/etc/udev/rules.d/59-vial.rules`, `/etc/udev/rules.d/99-vial.rules` — Vial keyboard access
- `/etc/keyd/default.conf` — Caps Lock → Backspace
- `/usr/local/bin/mkinitcpio` — warns when Limine boot entries need `limine-mkinitcpio`

## Notes

- `herdr` binary lives in `~/.local/bin` and `pi` comes from bun; neither is
  tracked here (reinstall them after a disk wipe).
