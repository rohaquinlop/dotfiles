#!/usr/bin/env bash
# Universal paste (Omarchy SUPER+V).
#
# Terminals receive Shift+Insert (their "paste clipboard" binding), every other
# app receives Ctrl+V.
set -u

command -v wtype >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

terminals='^(Alacritty|alacritty|foot|footclient|kitty|ghostty|com.mitchellh.ghostty|WezTerm|org.wezfurlong.wezterm|kgx|org.gnome.Console|konsole|Terminator|xterm|XTerm)$'

app_id=$(niri msg --json focused-window 2>/dev/null | jq -r '.app_id // empty' 2>/dev/null)

if [[ "$app_id" =~ $terminals ]]; then
  exec wtype -M shift -k Insert -m shift
else
  exec wtype -M ctrl -k v -m ctrl
fi
