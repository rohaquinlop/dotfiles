# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# Auto-launch zsh shell if in interactive bash
if command -v zsh &> /dev/null; then
  # The SHLVL guard from the upstream omarchy-zsh template is removed here:
  # herdr panes (and any nested interactive bash) inherit SHLVL > 1, which
  # silently skipped the exec and left panes on bash without git shortcuts.
  if [[ $(ps --no-header --pid=$PPID --format=comm) != "zsh" && -z ${BASH_EXECUTION_STRING} ]]
  then
    shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''
    exec zsh $LOGIN_OPTION
  fi
fi

# Load shared shell configuration (bash fallback when zsh is unavailable)
[[ -f /usr/share/omarchy-zsh/shell/all ]] && source /usr/share/omarchy-zsh/shell/all

# Add your own exports, aliases, and functions below.
# Force mise to install pi from npm (the aqua/GitHub-release build can't load
# user extensions with external deps, e.g. pdf-parse/jsdom).
export MISE_BACKENDS_PI="npm:@earendil-works/pi-coding-agent"
. "$HOME/.cargo/env"
