#!/bin/bash
# Dotfiles installer. Omarchy is detected and gets only the packages that
# apply there; the CachyOS + niri machine and the MacBook keep the full set.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if command -v omarchy >/dev/null 2>&1 || [ -d /usr/share/omarchy ]; then
  OMARCHY=true
else
  OMARCHY=false
fi

# Omarchy already owns Hyprland, the bar, the lock screen, btop, herdr and the
# bash startup files. Share only the personal shell, terminal, prompt, git and
# editor configs, plus the Caps Lock override.
if $OMARCHY; then
  STOW_PACKAGES=(zsh alacritty starship git zed hypr dsh)
else
  STOW_PACKAGES=(zsh bash alacritty nvim starship btop git gh herdr niri config-misc noctalia)
fi

BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Move existing regular files out of the way so stow can create its symlinks.
# (First run on a fresh OS: the distro's default .zshrc, alacritty config, etc.)
backup_conflicts() {
  local pkg="$1" src rel dst
  while IFS= read -r src; do
    rel="${src#"$DOTFILES_DIR/$pkg/"}"
    dst="$HOME/$rel"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$dst" "$BACKUP_DIR/$rel"
      log_warn "backed up ~/$rel"
    fi
  done < <(find "$DOTFILES_DIR/$pkg" -type f)
}

stow_packages() {
  log_info "Stowing user packages..."
  local failed=0
  for pkg in "${STOW_PACKAGES[@]}"; do
    if [ ! -d "$DOTFILES_DIR/$pkg" ]; then
      log_warn "Package not found: $pkg"
      continue
    fi

    backup_conflicts "$pkg"

    if stow --no-folding -t ~ "$pkg" 2>/dev/null; then
      log_ok "$pkg"
    else
      log_error "Failed: $pkg"
      ((failed++)) || true
    fi
  done
  if [ "$failed" -gt 0 ]; then
    log_error "$failed package(s) failed"
    return 1
  fi
}

# alacritty.toml imports ~/.config/alacritty/font.toml; point it at this OS's
# font file (Noto Sans Mono on Linux, JetBrainsMono Nerd Font on macOS).
# The import is optional in alacritty, so a missing link fails silently and
# the terminal falls back to "monospace" (plain Noto Sans Mono, no Nerd Font
# glyphs). Verify the stow-deployed target before linking, and fail loudly.
# Then generate the powerline cap alignment for the current font size and
# output scale into ~/.config/alacritty/local.toml.
setup_alacritty_font() {
  local os=linux
  [ "$(uname -s)" = Darwin ] && os=macos
  local target="$HOME/.config/alacritty/fonts/$os.toml"

  if [ ! -e "$target" ]; then
    log_error "alacritty font: $target not found"
    echo "  stow --no-folding -t ~ alacritty"
    return 1
  fi

  ln -sfn "fonts/$os.toml" "$HOME/.config/alacritty/font.toml"
  log_ok "alacritty font: fonts/$os.toml"

  if "$HOME/.local/bin/alacritty-font-size" sync >/dev/null; then
    log_ok "alacritty font alignment: local.toml"
  else
    log_warn "could not sync alacritty font alignment"
  fi
}

# Noctalia renders the palette into the apps (see [theme.templates] in
# noctalia/.config/noctalia/config.toml). Not used on Omarchy: its own theme
# system owns that. On the niri machine the daemon may not be running yet, so
# a config that includes the generated noctalia.kdl would fail to load. An
# empty file is valid KDL, so niri starts on the Akane fallback and the shell
# fills the file in at login.
apply_app_templates() {
  if $OMARCHY; then
    return 0
  fi

  log_info "Rendering Noctalia app templates..."

  if [ ! -e "$HOME/.config/niri/noctalia.kdl" ]; then
    mkdir -p "$HOME/.config/niri"
    : >"$HOME/.config/niri/noctalia.kdl"
    log_warn "wrote an empty ~/.config/niri/noctalia.kdl (niri include fallback)"
  fi

  if command -v noctalia >/dev/null 2>&1 && noctalia msg templates-apply >/dev/null 2>&1; then
    log_ok "app templates applied"
  else
    log_warn "noctalia is not running — run 'noctalia msg templates-apply' after login"
  fi
}

# Stow only links the units a package ships under ~/.config/systemd/user; they
# still have to be enabled, and restarted so an updated unit or script is used.
enable_user_services() {
  if ! command -v systemctl >/dev/null 2>&1 || ! systemctl --user show-environment >/dev/null 2>&1; then
    log_warn "no systemd user session — skipping"
    return 0
  fi

  log_info "Enabling user services..."
  systemctl --user daemon-reload || log_warn "could not reload user units"

  # Omarchy: only the harness service. It starts at the next login and is not
  # started here, because a manual `dsh web` may already own port 3080.
  if $OMARCHY; then
    if [ -f "$HOME/.config/systemd/user/dsh-web.service" ]; then
      if systemctl --user enable dsh-web.service >/dev/null 2>&1; then
        log_ok "dsh-web.service (starts at next login)"
      else
        log_warn "could not enable dsh-web.service"
      fi
    fi
    # The harness is not a package, so nothing else updates it. The timer runs
    # the staged update; it is safe to start now because it does nothing when
    # the published version matches the installed one.
    if [ -f "$HOME/.config/systemd/user/dsh-update.timer" ]; then
      if systemctl --user enable --now dsh-update.timer >/dev/null 2>&1; then
        log_ok "dsh-update.timer (daily harness update check)"
      else
        log_warn "could not enable dsh-update.timer"
      fi
    fi
    return 0
  fi

  local unit
  for unit in config-misc/.config/systemd/user/*.service; do
    [ -f "$unit" ] || continue
    unit="$(basename "$unit")"
    if systemctl --user enable "$unit" >/dev/null 2>&1; then
      log_ok "$unit"
    else
      log_warn "could not enable $unit"
      continue
    fi
    systemctl --user restart "$unit" >/dev/null 2>&1 || log_warn "could not start $unit"
  done
}

# Caps Lock as Backspace comes from keyd on both machines: it applies below the
# compositor, so the TTY and the desktop share one mapping. hypr/input.lua sets
# the same option inside Hyprland as a fallback when keyd is not running.
install_keyd() {
  if [ ! -d system/keyd ]; then
    return 0
  fi

  if ! command -v keyd >/dev/null 2>&1; then
    log_warn "keyd is not installed — skipping keyd config and service"
    return 0
  fi

  log_info "Installing keyd config (requires sudo)..."
  sudo mkdir -p /etc/keyd
  local conf
  for conf in system/keyd/*.conf; do
    [ -f "$conf" ] || continue
    sudo cp "$conf" "/etc/keyd/$(basename "$conf")"
    log_ok "keyd config: $(basename "$conf")"
  done

  if sudo systemctl enable --now keyd >/dev/null 2>&1; then
    log_ok "keyd.service"
  else
    log_warn "could not enable keyd.service"
  fi

  if keyd check >/dev/null 2>&1; then
    log_ok "keyd config valid"
  else
    log_warn "keyd config check failed — run: keyd check"
  fi
}

install_system_files() {
  if $OMARCHY; then
    log_info "Omarchy detected: SDDM, Limine and udev files stay untouched."
    return 0
  fi

  log_info "Installing system-level files (requires sudo)..."

  if [ -d system/sddm/themes ] && command -v sddm >/dev/null 2>&1; then
    sudo mkdir -p /usr/share/sddm/themes /etc/sddm.conf.d
    # Replace the theme wholesale so deleted files do not linger.
    sudo rm -rf /usr/share/sddm/themes/cachyos
    sudo cp -r system/sddm/themes/cachyos /usr/share/sddm/themes/cachyos
    sudo chown -R root:root /usr/share/sddm/themes/cachyos
    sudo chmod -R a+rX /usr/share/sddm/themes/cachyos
    log_ok "sddm theme: cachyos"

    for conf in system/sddm/sddm.conf.d/*.conf; do
      [ -f "$conf" ] || continue
      sudo cp "$conf" "/etc/sddm.conf.d/$(basename "$conf")"
      log_ok "sddm config: $(basename "$conf")"
    done
    log_info "Login screen preview: sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/cachyos"
  else
    log_warn "sddm is not installed — skipping login screen theme"
  fi

  for rule in system/udev/rules.d/*.rules; do
    [ -f "$rule" ] || continue
    sudo cp "$rule" "/etc/udev/rules.d/$(basename "$rule")"
    log_ok "udev rule: $(basename "$rule")"
  done

  # i2c-dev gives ddcutil its /dev/i2c-* devices, which the external monitor
  # needs for brightness control (it has no backlight device of its own).
  if [ -d system/modules-load.d ]; then
    for conf in system/modules-load.d/*.conf; do
      [ -f "$conf" ] || continue
      sudo cp "$conf" "/etc/modules-load.d/$(basename "$conf")"
      log_ok "modules-load: $(basename "$conf")"
    done
    sudo modprobe i2c-dev 2>/dev/null && log_ok "i2c-dev" || log_warn "could not load i2c-dev — reboot to get monitor brightness"
  fi

  for script in system/local/bin/*; do
    [ -f "$script" ] || continue
    sudo cp "$script" "/usr/local/bin/$(basename "$script")"
    sudo chmod +x "/usr/local/bin/$(basename "$script")"
    log_ok "script: /usr/local/bin/$(basename "$script")"
  done

  if [ -d system/systemd ]; then
    for unit in system/systemd/*; do
      [ -f "$unit" ] || continue
      sudo cp "$unit" "/etc/systemd/system/$(basename "$unit")"
      log_ok "systemd unit: $(basename "$unit")"
    done
    sudo systemctl daemon-reload

    # Watches Noctalia's settings.toml, so changing the wallpaper rebuilds the
    # login and lock screen backgrounds without another install run.
    if sudo systemctl enable --now sddm-theme-sync.path >/dev/null 2>&1; then
      log_ok "sddm-theme-sync.path"
    else
      log_warn "could not enable sddm-theme-sync.path"
    fi   # the sync script itself is installed just above, by the local/bin loop
    if sudo /usr/local/bin/sddm-theme-sync; then
      log_ok "login + lock screen backgrounds and greeter colours"
    else
      log_warn "theme sync failed — check that a wallpaper is set in Noctalia"
    fi
  fi

  sudo udevadm control --reload-rules
  sudo udevadm trigger
  log_ok "System files installed"
}

omarchy_notes() {
  log_info "Caps Lock -> Backspace is installed through keyd (system-wide)."
  log_info "hypr/input.lua keeps the same mapping as a Hyprland fallback."
  echo "  hyprctl reload"

  if [ -f "$HOME/.config/systemd/user/dsh-web.service" ]; then
    log_info "DeepSeek Harness: open it from SUPER+SPACE (starts at next login)."
  fi

  local login_shell
  login_shell="$(getent passwd "$USER" | cut -d: -f7)"

  if ! command -v zsh >/dev/null 2>&1; then
    log_warn "zsh is not installed yet; the new ~/.zshrc is inactive until it is."
    echo "  sudo pacman -S --needed \$(tr '\\n' ' ' < packages-omarchy.txt)"
    echo "  chsh -s /usr/bin/zsh"
  elif [ "$login_shell" != /usr/bin/zsh ] && [ "$login_shell" != /bin/zsh ]; then
    log_warn "zsh is installed, but the login shell is $login_shell."
    echo "  chsh -s /usr/bin/zsh"
  else
    log_ok "zsh is the login shell"
  fi

  if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
    if hyprctl reload >/dev/null 2>&1; then
      log_ok "Hyprland reloaded"
    else
      log_warn "could not reload Hyprland; run: hyprctl reload"
    fi
  fi
}

main() {
  echo ""
  echo "=========================================="
  if $OMARCHY; then
    echo "  Dotfiles Installer (Omarchy)"
  else
    echo "  Dotfiles Installer (CachyOS + niri)"
  fi
  echo "=========================================="
  echo ""

  if ! command -v stow >/dev/null 2>&1; then
    log_error "stow is not installed."
    if $OMARCHY; then
      echo "  sudo pacman -S --needed \$(tr '\\n' ' ' < packages-omarchy.txt)"
    else
      echo "  sudo pacman -S --needed \$(tr '\\n' ' ' < packages.txt)"
    fi
    exit 1
  fi

  stow_packages
  setup_alacritty_font
  echo ""
  apply_app_templates
  echo ""
  enable_user_services
  echo ""
  install_keyd
  echo ""
  install_system_files

  if $OMARCHY; then
    echo ""
    omarchy_notes
  fi

  echo ""
  echo "=========================================="
  echo "  Installation Complete!"
  echo "=========================================="
  echo ""
  log_info "Restart your shell for changes to take effect."
  [ -d "$BACKUP_DIR" ] && log_info "Old configs backed up to $BACKUP_DIR"
}

main "$@"
