#!/bin/bash
# Dotfiles installer for CachyOS + niri (also used by the MacBook for syncing).
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

STOW_PACKAGES=(
  shell alacritty
  nvim starship btop git gh
  herdr niri
  config-misc
  noctalia
)

BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Move existing regular files out of the way so stow can create its symlinks.
# (First run on a fresh OS: the distro's default .zshrc, niri config, etc.)
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

install_system_files() {
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

  if [ -d system/keyd ]; then
    sudo mkdir -p /etc/keyd
    for conf in system/keyd/*.conf; do
      [ -f "$conf" ] || continue
      sudo cp "$conf" "/etc/keyd/$(basename "$conf")"
      log_ok "keyd config: $(basename "$conf")"
    done
    if pacman -Qq keyd >/dev/null 2>&1; then
      sudo systemctl enable --now keyd 2>/dev/null && log_ok "keyd.service"
    else
      log_warn "keyd is not installed — skipping keyd.service"
    fi
  fi

  for script in system/local/bin/*; do
    [ -f "$script" ] || continue
    sudo cp "$script" "/usr/local/bin/$(basename "$script")"
    sudo chmod +x "/usr/local/bin/$(basename "$script")"
    log_ok "script: /usr/local/bin/$(basename "$script")"
  done

  sudo udevadm control --reload-rules
  sudo udevadm trigger
  log_ok "System files installed"
}

main() {
  echo ""
  echo "=========================================="
  echo "  Dotfiles Installer (CachyOS + niri)"
  echo "=========================================="
  echo ""

  if ! command -v stow >/dev/null 2>&1; then
    log_error "stow is not installed."
    echo "  sudo pacman -S --needed $(tr '\n' ' ' < packages.txt)"
    exit 1
  fi

  stow_packages
  echo ""
  install_system_files

  echo ""
  echo "=========================================="
  echo "  Installation Complete!"
  echo "=========================================="
  echo ""
  log_info "Restart your shell for changes to take effect."
  [ -d "$BACKUP_DIR" ] && log_info "Old configs backed up to $BACKUP_DIR"
}

main "$@"
