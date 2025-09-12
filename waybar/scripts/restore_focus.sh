#!/bin/bash

# Get the current workspace name
current_ws=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .name')

# Get all workspace names, excluding the current one to avoid unnecessary repeats
workspaces=$(swaymsg -t get_workspaces | jq -r '.[] | .name' | grep -v "^$current_ws$")

# Visit each workspace in order
for ws in $workspaces; do
  swaymsg workspace "$ws"
  sleep 0.1
done

# Return to the original workspace
swaymsg workspace "$current_ws"

