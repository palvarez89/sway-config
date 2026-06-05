#!/usr/bin/env bash
# Automatically adjust laptop screen scale depending on external displays.

set -euo pipefail

LAPTOP="eDP-1"

if [[ "${1:-}" == "--reload" ]]; then
    swaymsg reload >/dev/null
fi

# Get list of active (connected + enabled) outputs
active_outputs=$(swaymsg -t get_outputs -r | jq -r '.[] | select(.active == true) | .name')

# Count active outputs
count=$(wc -l <<<"$active_outputs")

if [ "$count" -gt 1 ]; then
    # At least one external monitor connected
    swaymsg output "$LAPTOP" scale 1.2 >/dev/null
else
    # Laptop screen only
    swaymsg output "$LAPTOP" scale 1.0 >/dev/null
fi
