# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Load zsh options, keybindings, and completion
[[ -f /usr/share/omarchy-zsh/shell/zoptions ]] && source /usr/share/omarchy-zsh/shell/zoptions

# Load shared shell configuration (aliases, functions, environment, tool init)
[[ -f /usr/share/omarchy-zsh/shell/all ]] && source /usr/share/omarchy-zsh/shell/all

# Add your own customizations below

# Bun global binaries
export PATH="$HOME/.cache/.bun/bin:$PATH"

# Aliases
alias oc='opencode'

# Git shortcuts (extending Omarchy's g, gcm, gcam)
alias gaa='git add --all'
alias gcb='git checkout -b'
alias gl='git pull'
alias gp='git push'

function deactivate_env() {
    if [ -n "$VIRTUAL_ENV" ]; then
        deactivate
    fi
}

function init_python_venv() {
    if [[ -d ".venv" ]]; then
        deactivate_env
        . "$PWD/.venv/bin/activate"
    fi
}

# Auto-activate venv on directory change
autoload -Uz add-zsh-hook
add-zsh-hook chpwd init_python_venv
init_python_venv  # activate in current directory on shell start

# zsh-hooks — multiplexing hooks for ZLE widgets
# Sourced after zsh-syntax-highlighting (loaded via zoptions) for proper hook chain
source ~/.config/zsh/plugins/zsh-hooks/zsh-hooks.plugin.zsh 2>/dev/null
