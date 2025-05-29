#!/bin/bash

status=$(dunstctl is-paused)

if [ "$1" == "toggle" ]; then
    dunstctl set-paused toggle
    status=$(dunstctl is-paused)
fi

if [ "$status" = "true" ]; then
    echo '{"text": "🔕", "tooltip": "Notifications paused", "class": "paused"}'
else
    echo '{"text": "🔔", "tooltip": "Notifications enabled", "class": "unpaused"}'
fi
