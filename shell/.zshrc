# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ── Options ─────────────────────────────────────────────────────────
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# ── History ─────────────────────────────────────────────────────────
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY      # record timestamps
setopt SHARE_HISTORY         # share history between open shells
setopt HIST_IGNORE_ALL_DUPS  # drop older duplicates
setopt HIST_IGNORE_SPACE     # don't record commands starting with a space
setopt HIST_VERIFY           # show expansion before running history commands

# ── Completion ──────────────────────────────────────────────────────
[[ -d /usr/share/zsh/plugins/zsh-completions ]] && fpath=(/usr/share/zsh/plugins/zsh-completions $fpath)
autoload -Uz compinit
compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:kill:*:processes' command 'ps -u $USER -o pid,comm'

# ── Helper: source the first readable file ──────────────────────────
_source_first() {
  local file
  for file in "$@"; do
    if [[ -r "$file" ]]; then
      source "$file"
      return 0
    fi
  done
  return 1
}

# ── Interactive plugins (need a terminal for ZLE) ───────────────────
if [[ -t 0 ]]; then
_source_first \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

_source_first \
  /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh \
  /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh \
  /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh

if (( $+widgets[history-substring-search-up] )); then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^P' history-substring-search-up
  bindkey '^N' history-substring-search-down
fi
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# fzf: key bindings + completion
if [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
elif [[ -r /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
  source /opt/homebrew/opt/fzf/shell/completion.zsh
elif [[ -r /usr/local/opt/fzf/shell/key-bindings.zsh ]]; then
  source /usr/local/opt/fzf/shell/key-bindings.zsh
  source /usr/local/opt/fzf/shell/completion.zsh
fi

# Noctalia's fzf theme (generated, colour-only, so it is safe to source after
# the key bindings; absent on machines without Noctalia).
[[ -r "$HOME/.config/fzf/themes/noctalia.sh" ]] && source "$HOME/.config/fzf/themes/noctalia.sh"
fi

# ── PATH / environment ──────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"

# ── Prompt ──────────────────────────────────────────────────────────
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# ── Navigation ──────────────────────────────────────────────────────
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
if command -v zoxide >/dev/null 2>&1; then
  # `cd` into an existing directory, otherwise jump with zoxide.
  alias cd='zd'
  zd() {
    if (( $# == 0 )); then
      builtin cd ~ || return
    elif [[ -d $1 ]]; then
      builtin cd "$1" || return
    else
      if ! z "$@"; then
        echo "Error: Directory not found"
        return 1
      fi
      printf '\U000F17A9 '
      pwd
    fi
  }
fi

# ── Aliases ─────────────────────────────────────────────────────────
if command -v eza >/dev/null 2>&1; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
else
  alias ls='ls --color=auto'
  alias lsa='ls -la'
fi
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

if command -v fzf >/dev/null 2>&1; then
  alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
  alias eff='$EDITOR "$(ff)"'
fi

# herdr (AI-agent terminal workspace manager)
alias h='herdr'
alias hws='herdr workspace create --cwd ~ --focus >/dev/null'

# nvim: `n` opens the current directory, `n <file>` opens a file
n() { if [ "$#" -eq 0 ]; then command nvim .; else command nvim "$@"; fi; }

# Git
alias g='git'
alias gst='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gl='git pull'
alias gp='git push'
alias glog='git log --oneline --graph --decorate'

# Arch/CachyOS helpers
if [[ "$OSTYPE" == linux* ]]; then
  alias update='sudo pacman -Syu'
  alias cleanup='sudo pacman -Rsn $(pacman -Qtdq)'
  alias rmpkg='sudo pacman -Rsn'
  alias fixpacman='sudo rm /var/lib/pacman/db.lck'
  alias jctl='journalctl -p 3 -xb'
  alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

  open() ( xdg-open "$@" >/dev/null 2>&1 & )

  # pkgfile: suggest the package that provides a missing command
  [[ -r /usr/share/doc/pkgfile/command-not-found.zsh ]] && \
    source /usr/share/doc/pkgfile/command-not-found.zsh
fi

# ── Python virtualenv: auto-activate .venv on cd ────────────────────
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

autoload -Uz add-zsh-hook
add-zsh-hook chpwd init_python_venv
init_python_venv

# ── Syntax highlighting (must be sourced last) ──────────────────────
if [[ -t 0 ]]; then
_source_first \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
