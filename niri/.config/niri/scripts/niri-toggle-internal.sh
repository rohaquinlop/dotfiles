#!/usr/bin/env bash
# Toggle the laptop panel on and off (Omarchy SUPER+P muscle memory).
#
# niri's config file is static: it cannot say "laptop panel off while the
# monitor is plugged in", because there is no way to test for a connected output
# there. So the panel is switched on demand instead, from this script.
#
# Two details worth keeping:
#   * `niri msg output ... off` is temporary. A config reload (any edit under
#     ~/.config/niri) forgets it and the panel comes back on by itself.
#   * It refuses to turn off the last enabled output. With the monitor unplugged,
#     a blind SUPER+P would otherwise black out the only screen you have.
set -u

command -v jq >/dev/null 2>&1 || exit 0

internal="${1:-eDP-1}"

outputs=$(niri msg --json outputs 2>/dev/null) || exit 0

# A disabled output is present in the dump with "logical": null.
internal_on() {
    jq -e --arg o "$internal" '.[$o].logical != null' <<<"$outputs" >/dev/null 2>&1
}

if internal_on; then
    enabled=$(jq '[.[] | select(.logical != null)] | length' <<<"$outputs")
    [ "$enabled" -le 1 ] && exit 0
    niri msg output "$internal" off
else
    niri msg output "$internal" on
fi
