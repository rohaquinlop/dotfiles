#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"
ZSH_HOOKS_REPO="https://github.com/zsh-hooks/zsh-hooks.git"
ZSH_HOOKS_DIR="$HOME/.config/zsh/plugins/zsh-hooks"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        local rel_path="${target#$HOME/}"
        local backup_path="$BACKUP_DIR/$rel_path"
        mkdir -p "$(dirname "$backup_path")"
        mv "$target" "$backup_path"
        log_warn "Backed up: $rel_path"
    elif [ -L "$target" ]; then
        rm "$target"
    fi
}

create_symlink() {
    local source="$1"
    local target="$2"
    mkdir -p "$(dirname "$target")"
    backup_if_exists "$target"
    ln -sf "$source" "$target"
}

# ============================================================
# Pre-flight checks
# ============================================================
preflight_checks() {
    log_info "Running pre-flight checks..."

    if [ ! -d "$DOTFILES_DIR" ]; then
        log_error "Dotfiles directory not found at $DOTFILES_DIR"
        exit 1
    fi

    if ! command -v git &>/dev/null; then
        log_error "git is not installed"
        exit 1
    fi

    if ! command -v bash &>/dev/null; then
        log_error "bash is not installed"
        exit 1
    fi

    log_success "Pre-flight checks passed"
}

# ============================================================
# Shell configuration
# ============================================================
install_shell_configs() {
    log_info "Installing shell configurations..."

    create_symlink "$DOTFILES_DIR/home/.zshrc" "$HOME/.zshrc"
    create_symlink "$DOTFILES_DIR/home/.bashrc" "$HOME/.bashrc"
    create_symlink "$DOTFILES_DIR/home/.bash_profile" "$HOME/.bash_profile"
    create_symlink "$DOTFILES_DIR/home/.profile" "$HOME/.profile"

    log_success "Shell configurations installed"
}

# ============================================================
# Hyprland
# ============================================================
install_hyprland_configs() {
    log_info "Installing Hyprland configurations..."

    local files=(
        hyprland.conf monitors.conf bindings.conf input.conf
        looknfeel.conf gaming.conf hypridle.conf
        hypridle-balanced.conf hypridle-performance.conf
        hypridle-power-saver.conf hyprlock.conf hyprsunset.conf
        autostart.conf xdph.conf
    )

    for f in "${files[@]}"; do
        create_symlink "$DOTFILES_DIR/config/hypr/$f" "$HOME/.config/hypr/$f"
    done

    create_symlink "$DOTFILES_DIR/config/hypr/scripts/fix-thermald.sh" "$HOME/.config/hypr/scripts/fix-thermald.sh"

    log_success "Hyprland configurations installed"
}

# ============================================================
# Terminals
# ============================================================
install_terminal_configs() {
    log_info "Installing terminal configurations..."

    create_symlink "$DOTFILES_DIR/config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
    create_symlink "$DOTFILES_DIR/config/foot/foot.ini" "$HOME/.config/foot/foot.ini"
    create_symlink "$DOTFILES_DIR/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"

    log_success "Terminal configurations installed"
}

# ============================================================
# Neovim
# ============================================================
install_nvim_configs() {
    log_info "Installing Neovim configurations..."

    create_symlink "$DOTFILES_DIR/config/nvim/lazyvim.json" "$HOME/.config/nvim/lazyvim.json"
    create_symlink "$DOTFILES_DIR/config/nvim/stylua.toml" "$HOME/.config/nvim/stylua.toml"
    create_symlink "$DOTFILES_DIR/config/nvim/.neoconf.json" "$HOME/.config/nvim/.neoconf.json"
    create_symlink "$DOTFILES_DIR/config/nvim/lua/config/lazy.lua" "$HOME/.config/nvim/lua/config/lazy.lua"
    create_symlink "$DOTFILES_DIR/config/nvim/lua/config/options.lua" "$HOME/.config/nvim/lua/config/options.lua"
    create_symlink "$DOTFILES_DIR/config/nvim/lua/config/keymaps.lua" "$HOME/.config/nvim/lua/config/keymaps.lua"
    create_symlink "$DOTFILES_DIR/config/nvim/lua/config/autocmds.lua" "$HOME/.config/nvim/lua/config/autocmds.lua"
    create_symlink "$DOTFILES_DIR/config/nvim/lua/plugins/theme.lua" "$HOME/.config/nvim/lua/plugins/theme.lua"
    create_symlink "$DOTFILES_DIR/config/nvim/lua/plugins/all-themes.lua" "$HOME/.config/nvim/lua/plugins/all-themes.lua"
    create_symlink "$DOTFILES_DIR/config/nvim/lua/plugins/omarchy-theme-hotreload.lua" "$HOME/.config/nvim/lua/plugins/omarchy-theme-hotreload.lua"
    create_symlink "$DOTFILES_DIR/config/nvim/lua/plugins/snacks-animated-scrolling-off.lua" "$HOME/.config/nvim/lua/plugins/snacks-animated-scrolling-off.lua"
    create_symlink "$DOTFILES_DIR/config/nvim/lua/plugins/disable-news-alert.lua" "$HOME/.config/nvim/lua/plugins/disable-news-alert.lua"
    create_symlink "$DOTFILES_DIR/config/nvim/plugin/after/transparency.lua" "$HOME/.config/nvim/plugin/after/transparency.lua"

    log_success "Neovim configurations installed"
}

# ============================================================
# Shell tools
# ============================================================
install_shell_tools_configs() {
    log_info "Installing shell tools configurations..."

    create_symlink "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"
    create_symlink "$DOTFILES_DIR/config/btop/btop.conf" "$HOME/.config/btop/btop.conf"
    create_symlink "$DOTFILES_DIR/config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
    create_symlink "$DOTFILES_DIR/config/git/config" "$HOME/.config/git/config"
    create_symlink "$DOTFILES_DIR/config/gh/config.yml" "$HOME/.config/gh/config.yml"
    create_symlink "$DOTFILES_DIR/config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
    create_symlink "$DOTFILES_DIR/config/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"
    create_symlink "$DOTFILES_DIR/config/mise/config.toml" "$HOME/.config/mise/config.toml"

    log_success "Shell tools configurations installed"
}

# ============================================================
# Notifications and OSD
# ============================================================
install_notification_configs() {
    log_info "Installing notification and OSD configurations..."

    create_symlink "$DOTFILES_DIR/config/mako/config" "$HOME/.config/mako/config"
    create_symlink "$DOTFILES_DIR/config/swayosd/config.toml" "$HOME/.config/swayosd/config.toml"
    create_symlink "$DOTFILES_DIR/config/swayosd/style.css" "$HOME/.config/swayosd/style.css"

    log_success "Notification and OSD configurations installed"
}

# ============================================================
# Application configs
# ============================================================
install_app_configs() {
    log_info "Installing application configurations..."

    create_symlink "$DOTFILES_DIR/config/gamemode.ini" "$HOME/.config/gamemode.ini"
    create_symlink "$DOTFILES_DIR/config/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"
    create_symlink "$DOTFILES_DIR/config/gtk-3.0/bookmarks" "$HOME/.config/gtk-3.0/bookmarks"
    create_symlink "$DOTFILES_DIR/config/imv/config" "$HOME/.config/imv/config"
    create_symlink "$DOTFILES_DIR/config/obsidian/user-flags.conf" "$HOME/.config/obsidian/user-flags.conf"
    create_symlink "$DOTFILES_DIR/config/chromium-flags.conf" "$HOME/.config/chromium-flags.conf"
    create_symlink "$DOTFILES_DIR/config/mimeapps.list" "$HOME/.config/mimeapps.list"

    log_success "Application configurations installed"
}

# ============================================================
# Opencode
# ============================================================
install_opencode_configs() {
    log_info "Installing opencode configurations..."

    create_symlink "$DOTFILES_DIR/config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
    create_symlink "$DOTFILES_DIR/config/opencode/tui.json" "$HOME/.config/opencode/tui.json"
    create_symlink "$DOTFILES_DIR/config/opencode/agents/researcher.md" "$HOME/.config/opencode/agents/researcher.md"
    create_symlink "$DOTFILES_DIR/config/opencode/agents/reviewer.md" "$HOME/.config/opencode/agents/reviewer.md"
    create_symlink "$DOTFILES_DIR/config/opencode/skills/create-pr/SKILL.md" "$HOME/.config/opencode/skills/create-pr/SKILL.md"
    create_symlink "$DOTFILES_DIR/config/opencode/skills/git-commit/SKILL.md" "$HOME/.config/opencode/skills/git-commit/SKILL.md"
    create_symlink "$DOTFILES_DIR/config/opencode/skills/release-notes/SKILL.md" "$HOME/.config/opencode/skills/release-notes/SKILL.md"

    log_success "Opencode configurations installed"
}

# ============================================================
# Omarchy
# ============================================================
install_omarchy_configs() {
    log_info "Installing Omarchy configurations..."

    create_symlink "$DOTFILES_DIR/config/omarchy/current/theme.name" "$HOME/.config/omarchy/current/theme.name"
    create_symlink "$DOTFILES_DIR/config/omarchy/current/background" "$HOME/.config/omarchy/current/background"
    create_symlink "$DOTFILES_DIR/config/omarchy/branding/about.txt" "$HOME/.config/omarchy/branding/about.txt"
    create_symlink "$DOTFILES_DIR/config/omarchy/branding/screensaver.txt" "$HOME/.config/omarchy/branding/screensaver.txt"
    create_symlink "$DOTFILES_DIR/config/omarchy/extensions/menu.sh" "$HOME/.config/omarchy/extensions/menu.sh"
    create_symlink "$DOTFILES_DIR/config/omarchy/hooks/theme-set" "$HOME/.config/omarchy/hooks/theme-set"

    # Theme files
    for f in "$DOTFILES_DIR/config/omarchy/current/theme/"*; do
        local fname=$(basename "$f")
        create_symlink "$f" "$HOME/.config/omarchy/current/theme/$fname"
    done

    log_success "Omarchy configurations installed"
}

# ============================================================
# Elephant / Walker
# ============================================================
install_elephant_configs() {
    log_info "Installing Elephant and Walker configurations..."

    create_symlink "$DOTFILES_DIR/config/elephant/calc.toml" "$HOME/.config/elephant/calc.toml"
    create_symlink "$DOTFILES_DIR/config/elephant/clipboard.toml" "$HOME/.config/elephant/clipboard.toml"
    create_symlink "$DOTFILES_DIR/config/elephant/desktopapplications.toml" "$HOME/.config/elephant/desktopapplications.toml"
    create_symlink "$DOTFILES_DIR/config/elephant/symbols.toml" "$HOME/.config/elephant/symbols.toml"
    create_symlink "$DOTFILES_DIR/config/elephant/menus/omarchy_background_selector.lua" "$HOME/.config/elephant/menus/omarchy_background_selector.lua"
    create_symlink "$DOTFILES_DIR/config/elephant/menus/omarchy_themes.lua" "$HOME/.config/elephant/menus/omarchy_themes.lua"
    create_symlink "$DOTFILES_DIR/config/elephant/menus/omarchy_unlocks.lua" "$HOME/.config/elephant/menus/omarchy_unlocks.lua"
    create_symlink "$DOTFILES_DIR/config/walker/config.toml" "$HOME/.config/walker/config.toml"
    create_symlink "$DOTFILES_DIR/config/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
    create_symlink "$DOTFILES_DIR/config/waybar/style.css" "$HOME/.config/waybar/style.css"

    log_success "Elephant and Walker configurations installed"
}

# ============================================================
# Input method
# ============================================================
install_input_method_configs() {
    log_info "Installing input method configurations..."

    create_symlink "$DOTFILES_DIR/config/fcitx5/profile" "$HOME/.config/fcitx5/profile"
    create_symlink "$DOTFILES_DIR/config/fcitx5/conf/clipboard.conf" "$HOME/.config/fcitx5/conf/clipboard.conf"
    create_symlink "$DOTFILES_DIR/config/fcitx5/conf/notifications.conf" "$HOME/.config/fcitx5/conf/notifications.conf"
    create_symlink "$DOTFILES_DIR/config/fcitx5/conf/xcb.conf" "$HOME/.config/fcitx5/conf/xcb.conf"
    create_symlink "$DOTFILES_DIR/config/environment.d/fcitx.conf" "$HOME/.config/environment.d/fcitx.conf"

    log_success "Input method configurations installed"
}

# ============================================================
# Autostart
# ============================================================
install_autostart_configs() {
    log_info "Installing autostart configurations..."

    create_symlink "$DOTFILES_DIR/config/autostart/1password.desktop" "$HOME/.config/autostart/1password.desktop"
    create_symlink "$DOTFILES_DIR/config/autostart/walker.desktop" "$HOME/.config/autostart/walker.desktop"

    log_success "Autostart configurations installed"
}

# ============================================================
# Desktop entries and icons
# ============================================================
install_desktop_entries() {
    log_info "Installing desktop entries and icons..."

    local desktop_files=(
        Discord.desktop YAPYAP.desktop
        "DAVE THE DIVER.desktop" "Disk Usage.desktop"
        Docker.desktop mpv.desktop typora.desktop
    )

    for f in "${desktop_files[@]}"; do
        create_symlink "$DOTFILES_DIR/local/share/applications/$f" "$HOME/.local/share/applications/$f"
    done

    # Application icons
    for f in "$DOTFILES_DIR/local/share/applications/icons/"*.png; do
        local fname=$(basename "$f")
        create_symlink "$f" "$HOME/.local/share/applications/icons/$fname"
    done

    # Hicolor icons
    for size_dir in "$DOTFILES_DIR/local/share/icons/hicolor/"*/; do
        local size=$(basename "$size_dir")
        for f in "$size_dir"apps/*; do
            [ -f "$f" ] || continue
            local fname=$(basename "$f")
            create_symlink "$f" "$HOME/.local/share/icons/hicolor/$size/apps/$fname"
        done
    done

    log_success "Desktop entries and icons installed"
}

# ============================================================
# Omarchy state
# ============================================================
install_omarchy_state() {
    log_info "Installing Omarchy state..."

    create_symlink "$DOTFILES_DIR/local/state/omarchy/toggles/hypr/flags.conf" "$HOME/.local/state/omarchy/toggles/hypr/flags.conf"

    log_success "Omarchy state installed"
}

# ============================================================
# Systemd user services
# ============================================================
install_systemd_services() {
    log_info "Installing systemd user services..."

    create_symlink "$DOTFILES_DIR/systemd/user/omarchy-recover-internal-monitor.service" "$HOME/.config/systemd/user/omarchy-recover-internal-monitor.service"
    create_symlink "$DOTFILES_DIR/systemd/user/omarchy-battery-monitor.service" "$HOME/.config/systemd/user/omarchy-battery-monitor.service"
    create_symlink "$DOTFILES_DIR/systemd/user/omarchy-battery-monitor.timer" "$HOME/.config/systemd/user/omarchy-battery-monitor.timer"
    create_symlink "$DOTFILES_DIR/systemd/user/elephant.service" "$HOME/.config/systemd/user/elephant.service"
    create_symlink "$DOTFILES_DIR/systemd/user/swayosd-server.service" "$HOME/.config/systemd/user/swayosd-server.service"

    mkdir -p "$HOME/.config/systemd/user/app-walker@autostart.service.d"
    create_symlink "$DOTFILES_DIR/systemd/user/app-walker@autostart.service.d/restart.conf" "$HOME/.config/systemd/user/app-walker@autostart.service.d/restart.conf"

    log_success "Systemd user services installed"
}

# ============================================================
# System-level files (requires sudo)
# ============================================================
install_system_files() {
    log_info "Installing system-level files (requires sudo)..."

    # Udev rules
    local udev_rules=(
        99-battery-thresholds.rules
        99-power-profile.rules
        99-wifi-powersave.rules
        99-vial.rules
        59-vial.rules
    )

    for rule in "${udev_rules[@]}"; do
        if [ -f "$DOTFILES_DIR/system/udev/rules.d/$rule" ]; then
            sudo cp "$DOTFILES_DIR/system/udev/rules.d/$rule" "/etc/udev/rules.d/$rule"
            log_success "Installed udev rule: $rule"
        fi
    done

    # /usr/local/bin scripts
    local bin_scripts=(thinkpad-desk-mode.sh mkinitcpio)
    for script in "${bin_scripts[@]}"; do
        if [ -f "$DOTFILES_DIR/system/local/bin/$script" ]; then
            sudo cp "$DOTFILES_DIR/system/local/bin/$script" "/usr/local/bin/$script"
            sudo chmod +x "/usr/local/bin/$script"
            log_success "Installed script: /usr/local/bin/$script"
        fi
    done

    # Systemd system services
    if [ -d "$DOTFILES_DIR/systemd/system" ]; then
        for service in "$DOTFILES_DIR/systemd/system/"*.service; do
            [ -f "$service" ] || continue
            local svc_name=$(basename "$service")
            sudo cp "$service" "/etc/systemd/system/$svc_name"
            sudo systemctl enable "$svc_name"
            log_success "Installed and enabled systemd service: $svc_name"
        done
        sudo systemctl daemon-reload
    fi

    # Reload udev rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger

    log_success "System-level files installed"
}

# ============================================================
# Zsh plugins
# ============================================================
install_zsh_plugins() {
    log_info "Installing zsh plugins..."

    if [ ! -d "$ZSH_HOOKS_DIR" ]; then
        git clone "$ZSH_HOOKS_REPO" "$ZSH_HOOKS_DIR"
        log_success "Cloned zsh-hooks plugin"
    else
        log_warn "zsh-hooks already installed, skipping"
    fi
}

# ============================================================
# Reload services
# ============================================================
reload_services() {
    log_info "Reloading services..."

    # Reload Hyprland
    if command -v hyprctl &>/dev/null; then
        hyprctl reload 2>/dev/null || true
        log_success "Hyprland reloaded"
    fi

    # Restart waybar
    if command -v omarchy &>/dev/null; then
        omarchy restart waybar 2>/dev/null || true
        log_success "Waybar restarted"
    fi

    # Restart walker
    if command -v omarchy &>/dev/null; then
        omarchy restart walker 2>/dev/null || true
        log_success "Walker restarted"
    fi

    # Restart terminal
    if command -v omarchy &>/dev/null; then
        omarchy restart terminal 2>/dev/null || true
        log_success "Terminal restarted"
    fi

    # Reload systemd user daemon
    systemctl --user daemon-reload 2>/dev/null || true

    log_success "Services reloaded"
}

# ============================================================
# Main
# ============================================================
main() {
    echo ""
    echo "=========================================="
    echo "  Omarchy Dotfiles Installer"
    echo "=========================================="
    echo ""

    preflight_checks

    install_shell_configs
    install_hyprland_configs
    install_terminal_configs
    install_nvim_configs
    install_shell_tools_configs
    install_notification_configs
    install_app_configs
    install_opencode_configs
    install_omarchy_configs
    install_elephant_configs
    install_input_method_configs
    install_autostart_configs
    install_desktop_entries
    install_omarchy_state
    install_systemd_services
    install_zsh_plugins
    install_system_files
    reload_services

    echo ""
    echo "=========================================="
    echo "  Installation Complete!"
    echo "=========================================="
    echo ""

    if [ -d "$BACKUP_DIR" ]; then
        log_info "Backups saved to: $BACKUP_DIR"
    fi

    log_info "You may need to restart your shell for changes to take effect."
    log_info "Run 'gh auth login' to authenticate GitHub CLI."
}

main "$@"
