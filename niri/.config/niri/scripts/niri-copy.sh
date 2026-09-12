#!/usr/bin/env bash
# Universal copy (Omarchy SUPER+C).
#
# Terminals receive Ctrl+Insert (their "copy selection" binding), every other
# app receives Ctrl+C. wtype injects the chord through the virtual keyboard
# protocol, which niri forwards to the focused surface only.
set -u

command -v wtype >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

terminals='^(Alacritty|alacritty|foot|footclient|kitty|ghostty|com.mitchellh.ghostty|WezTerm|org.wezfurlong.wezterm|kgx|org.gnome.Console|konsole|Terminator|xterm|XTerm)$'

app_id=$(niri msg --json focused-window 2>/dev/null | jq -r '.app_id // empty' 2>/dev/null)

if [[ "$app_id" =~ $terminals ]]; then
  exec wtype -M ctrl -k Insert -m ctrl
else
  exec wtype -M ctrl -k c -m ctrl
fi
