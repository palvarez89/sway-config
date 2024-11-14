#!/bin/bash
if swaymsg -t get_tree | jq '.. | objects | select(.inhibit_idle == true)' | grep -q "inhibit_idle"; then
    echo "🛑"
else
    echo ""
fi
