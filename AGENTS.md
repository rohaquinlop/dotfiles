# AGENTS.md

Dotfiles repo for Omarchy/Hyprland on Arch Linux (ThinkPad X1 Carbon Gen 9). Managed with GNU Stow.

## Architecture

27 stow packages. Each package directory mirrors the target path under `~`:

```
package-name/.config/app-name/files  →  ~/.config/app-name/files
package-name/.local/share/...        →  ~/.local/share/...
shell/.bashrc                        →  ~/.bashrc
```

Non-stowed directories (require `sudo cp`, handled by `install.sh`):
- `system/udev/rules.d/` → `/etc/udev/rules.d/`
- `system/local/bin/` → `/usr/local/bin/`
- `systemd/system/` → `/etc/systemd/system/`

## Critical Quirks

- **Always use `stow --no-folding`**. Without it, stow creates directory symlinks instead of individual file symlinks.
- **Hyprland cannot use stow**. Hyprland's watchdog overwrites directory symlinks with its own directory and regenerates a default `hyprland.conf`. The `hypr` package uses manual `ln -sf` per file in `install.sh`.
- **`local-icons` needs `--adopt`** on first run because icon files already exist as regular files in `~/.local/share/icons/`.

## Commands

```bash
# Full install
./install.sh

# Stow a single package
stow --no-folding -t ~ <package-name>

# Unstow a single package
stow -D -t ~ <package-name>

# Dry-run (check for conflicts)
stow --no-folding -n -v -t ~ <package-name>

# Adopt existing files into a package (first-time migration)
stow --no-folding --adopt -t ~ <package-name>
```

## Adding a New Package

```bash
mkdir -p new-pkg/.config/new-app
mv ~/.config/new-app/config new-pkg/.config/new-app/config
stow --no-folding -t ~ new-pkg
```

## Sensitive Files (Never Commit)

- `gh/gh/hosts.yml` — GitHub auth token
- `shell/.ssh/` — SSH keys
- `lazygit/lazygit/config.yml` — contains credentials
- `nvim/.config/nvim/lazy-lock.json` — generated lockfile

## Commit Conventions

Conventional Commits format. Recent history uses lowercase descriptions without scope for broad changes:

```
refactor: migrate dotfiles to GNU Stow
hypr: update monitor settings
fix: revert animation disable, causes flickering on Hyprland 0.55.2
```

## Systemd Services

User services are in `systemd-user/.config/systemd/user/`. After changing them:

```bash
systemctl --user daemon-reload
systemctl --user enable <service-name>
```
