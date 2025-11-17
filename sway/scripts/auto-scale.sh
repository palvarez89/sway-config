#!/usr/bin/env bash
# Automatically adjust laptop screen scale depending on external displays

LAPTOP="eDP-1"

# Get list of active (connected + enabled) outputs
active_outputs=$(swaymsg -t get_outputs | jq -r '.[] | select(.active==true) | .name')

# Count active outputs
count=$(echo "$active_outputs" | wc -l)

if [ "$count" -gt 1 ]; then
    # At least one external monitor connected
    swaymsg output "$LAPTOP" scale 1.2
else
    # Laptop screen only
    swaymsg output "$LAPTOP" scale 1.0
fi
