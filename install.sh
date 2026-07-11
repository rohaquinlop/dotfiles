#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
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

# Packages that work with normal stow (--no-folding)
STOW_PACKAGES=(
  shell alacritty foot kitty ghostty
  nvim starship btop tmux git gh lazygit mise
  mako swayosd walker waybar elephant omarchy opencode
  fcitx5 config-misc systemd-user
  desktop-entries local-icons local-state
)

# Packages that need --adopt on first run (have existing files)
ADOPT_PACKAGES=(local-icons)

# Hyprland's watchdog replaces directory symlinks with its own directory,
# so we create individual file symlinks manually instead of using stow.
install_hypr() {
  log_info "Installing hypr config (manual symlinks)..."
  local src="$DOTFILES_DIR/hypr/.config/hypr"
  local dst="$HOME/.config/hypr"
  mkdir -p "$dst/scripts"
  for f in "$src"/*.conf; do
    ln -sf "$f" "$dst/$(basename "$f")"
  done
  ln -sf "$src/scripts/fix-thermald.sh" "$dst/scripts/fix-thermald.sh"
  log_ok "hypr"
}

stow_packages() {
  log_info "Stowing user packages..."
  local failed=0
  for pkg in "${STOW_PACKAGES[@]}"; do
    if [ ! -d "$DOTFILES_DIR/$pkg" ]; then
      log_warn "Package not found: $pkg"
      continue
    fi

    local adopt_flag=""
    for ap in "${ADOPT_PACKAGES[@]}"; do
      if [ "$ap" = "$pkg" ]; then
        adopt_flag="--adopt"
        break
      fi
    done

    if stow --no-folding $adopt_flag -t ~ "$pkg" 2>/dev/null; then
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

enable_systemd_services() {
  log_info "Enabling systemd user services..."
  systemctl --user enable elephant.service 2>/dev/null && log_ok "elephant.service"
  systemctl --user enable swayosd-server.service 2>/dev/null && log_ok "swayosd-server.service"
  systemctl --user enable omarchy-battery-monitor.timer 2>/dev/null && log_ok "omarchy-battery-monitor.timer"
  systemctl --user enable omarchy-recover-internal-monitor.service 2>/dev/null && log_ok "omarchy-recover-internal-monitor.service"
}

install_system_files() {
  log_info "Installing system-level files (requires sudo)..."

  for rule in system/udev/rules.d/*.rules; do
    [ -f "$rule" ] || continue
    sudo cp "$rule" "/etc/udev/rules.d/$(basename "$rule")"
    log_ok "udev rule: $(basename "$rule")"
  done

  for script in system/local/bin/*; do
    [ -f "$script" ] || continue
    sudo cp "$script" "/usr/local/bin/$(basename "$script")"
    sudo chmod +x "/usr/local/bin/$(basename "$script")"
    log_ok "script: /usr/local/bin/$(basename "$script")"
  done

  for svc in systemd/system/*.service; do
    [ -f "$svc" ] || continue
    local svc_name
    svc_name=$(basename "$svc")
    sudo cp "$svc" "/etc/systemd/system/$svc_name"
    sudo systemctl enable "$svc_name"
    log_ok "system service: $svc_name"
  done

  sudo systemctl daemon-reload
  sudo udevadm control --reload-rules
  sudo udevadm trigger
  log_ok "System files installed"
}

reload_services() {
  log_info "Reloading services..."
  hyprctl reload 2>/dev/null && log_ok "Hyprland reloaded" || true
  systemctl --user daemon-reload 2>/dev/null && log_ok "systemd user daemon reloaded" || true
  command -v omarchy &>/dev/null && omarchy restart waybar 2>/dev/null && log_ok "Waybar restarted" || true
  command -v omarchy &>/dev/null && omarchy restart walker 2>/dev/null && log_ok "Walker restarted" || true
}

main() {
  echo ""
  echo "=========================================="
  echo "  Dotfiles Installer (stow)"
  echo "=========================================="
  echo ""

  install_hypr
  stow_packages
  echo ""
  enable_systemd_services
  echo ""
  install_system_files
  echo ""
  reload_services

  echo ""
  echo "=========================================="
  echo "  Installation Complete!"
  echo "=========================================="
  echo ""
  log_info "Restart your shell for changes to take effect."
}

main "$@"
