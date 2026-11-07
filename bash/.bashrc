# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# Hand off to zsh. TUI tools (herdr panes, etc.) may spawn bash, and the old
# SHLVL guard silently skipped those. `ps -o comm= -p` is the portable spell:
# the GNU-only flags (--no-header --pid= --format=) error on macOS's BSD ps,
# so the parent check never ran on the MacBook. The empty column header
# (`comm=`) is accepted by both GNU and BSD ps.
if command -v zsh &> /dev/null; then
  if [[ $(ps -o comm= -p $PPID) != "zsh" && -z ${BASH_EXECUTION_STRING} ]]
  then
    exec zsh
  fi
fi

if command -v eza &> /dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
else
  alias ls='ls --color=auto'
fi
alias ..='cd ..'
alias ...='cd ../..'
