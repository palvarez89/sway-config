#!/bin/bash

status=$(dunstctl is-paused)

if [ "$1" == "toggle" ]; then
    dunstctl set-paused toggle
    pkill -RTMIN+10 waybar  # send update signal
    exit 0
fi

# Print status in JSON
if [ "$status" = "true" ]; then
    echo '{"text": "🔕", "tooltip": "Notifications paused", "class": "paused"}'
else
    echo '{"text": "🔔", "tooltip": "Notifications enabled", "class": "unpaused"}'
fi
