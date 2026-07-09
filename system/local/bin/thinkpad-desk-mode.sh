#!/usr/bin/env bash
set -euo pipefail

DESK_START=40
DESK_END=60
MOBILE_START=75
MOBILE_END=100

BAT_PATH="/sys/class/power_supply/BAT0"
BHV_PATH="$BAT_PATH/charge_behaviour"
START_PATH="$BAT_PATH/charge_control_start_threshold"
END_PATH="$BAT_PATH/charge_control_end_threshold"
CAP_PATH="$BAT_PATH/capacity"

# ── Desk detection ──────────────────────────────────────────────
is_desk() {
    # Any external display connected (skip internal eDP/LVDS)
    for conn in /sys/class/drm/card*/card*-*/status; do
        case "$conn" in
            *eDP*|*LVDS*) continue ;;
        esac
        if grep -q "^connected" "$conn" 2>/dev/null; then
            return 0
        fi
    done
    return 1
}

# ── Apply thresholds ────────────────────────────────────────────
# Kernel requires start <= end at all times.
# Set the higher boundary first to avoid constraint violations.
set_thresholds() {
    local start="$1" end="$2"
    local cur_start cur_end
    cur_start=$(cat "$START_PATH")
    cur_end=$(cat "$END_PATH")

    if [ "$start" -gt "$cur_end" ]; then
        # Raising start above current end → raise end first
        echo "$end" > "$END_PATH"
        echo "$start" > "$START_PATH"
    elif [ "$end" -lt "$cur_start" ]; then
        # Lowering end below current start → lower start first
        echo "$start" > "$START_PATH"
        echo "$end" > "$END_PATH"
    else
        # Safe to set in any order
        echo "$start" > "$START_PATH"
        echo "$end" > "$END_PATH"
    fi
}

# ── Main ────────────────────────────────────────────────────────
if is_desk; then
    set_thresholds "$DESK_START" "$DESK_END"

    # Force-discharge if battery is above the stop threshold
    cap=$(cat "$CAP_PATH")
    if [ "$cap" -gt "$DESK_END" ]; then
        echo "force-discharge" > "$BHV_PATH"
    else
        echo "auto" > "$BHV_PATH"
    fi
else
    set_thresholds "$MOBILE_START" "$MOBILE_END"
    echo "auto" > "$BHV_PATH"
fi
