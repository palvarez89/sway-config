#!/bin/sh

# --- Ensure correct environment for Waybar or other launchers ---
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# --- Get the default input (source) from PipeWire metadata ---
default_source_json=$(pw-metadata 0 'default.audio.source' | sed -n "s/.* value:'\(.*\)' type.*/\1/p")
default_source_name=$(echo "$default_source_json" | jq -r '.name')

echo "Currently selected input: \"$default_source_name\""

# --- Get the object ID for the default input ---
default_source_id=$(pw-dump | jq -r --arg name "$default_source_name" '
  .[] | select(.type == "PipeWire:Interface:Node") |
  .info.props | select(."node.name" == $name) |
  ."object.id"
')

# --- List all other input sources ---
other_sources=$(pw-dump | jq -r --argjson cur "$default_source_id" '
  .[] | select(.type == "PipeWire:Interface:Node") |
  .info.props |
  select(."media.class" == "Audio/Source") |
  select(."object.id" != $cur) |
  "\(.["object.id"]) \(.["node.nick"] // .["media.name"] // .["node.description"] // .["device.description"] // .["node.name"])"
')

# --- Show the selection menu via rofi ---
selection=$(echo "$other_sources" | rofi -dmenu -p "Select Microphone Input")

# --- Handle cancel ---
if [ -z "$selection" ]; then
    exit 1
fi

# --- Extract selected ID ---
selection_id=$(echo "$selection" | awk '{print $1}')

# --- Change default input ---
wpctl set-default "$selection_id"

# --- Verify change ---
new_source_json=$(pw-metadata 0 'default.audio.source' | sed -n "s/.* value:'\(.*\)' type.*/\1/p")
new_source_name=$(echo "$new_source_json" | jq -r '.name')

new_source_id=$(pw-dump | jq -r --arg name "$new_source_name" '
  .[] | select(.type == "PipeWire:Interface:Node") |
  .info.props | select(."node.name" == $name) |
  ."object.id"
')

if [ "$new_source_id" != "$selection_id" ]; then
    notify-send "Failed to change audio input" -u critical -t 2000
    exit 1
fi

# --- Get friendly name for notification ---
new_source_nick=$(pw-dump | jq -r --arg name "$new_source_name" '
  .[] | select(.type == "PipeWire:Interface:Node") |
  .info.props | select(."node.name" == $name) |
  (."node.nick" // ."media.name" // ."node.description" // ."device.description" // $name)
')

notify-send "🎙️ Changed default audio input to $new_source_nick" -t 2000

