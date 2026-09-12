#!/usr/bin/env bash
# Universal cut (Omarchy SUPER+X). Ctrl+X works the same in terminals and apps.
set -u

command -v wtype >/dev/null 2>&1 || exit 0

exec wtype -M ctrl -k x -m ctrl
