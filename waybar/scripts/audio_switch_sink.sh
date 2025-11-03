#!/bin/sh

# === Get current default sink ===
default_sink_json=$(pw-metadata 0 'default.audio.sink' | sed -n "s/.* value:'\(.*\)' type.*/\1/p")
default_sink_name=$(echo "$default_sink_json" | jq -r '.name')

echo "Currently selected: \"$default_sink_name\""

# === Find current sink ID ===
default_sink_id=$(pw-dump | jq -r --arg name "$default_sink_name" '
  .[] | select(.type == "PipeWire:Interface:Node") |
  .info.props | select(."node.name" == $name) |
  ."object.id"
')

# === Collect all other playback sinks (exclude current) ===
other_sinks=$(pw-dump | jq -r --argjson cur "$default_sink_id" '
  .[] | select(.type == "PipeWire:Interface:Node") |
  .info.props |
  select(."media.class" == "Audio/Sink") |
  select(."object.id" != $cur) |
  "\(.["object.id"]) \(.["node.nick"] // .["media.name"] // .["node.description"] // .["device.description"] // .["node.name"])"
')

echo "other_sinks variable:"
echo $other_sinks

# === Present choices via rofi ===
selection=$(echo "$other_sinks" | rofi -dmenu -p "Select Audio Output")

# === Handle cancel ===
if [ -z "$selection" ]; then
    exit 1
fi

# === Extract selected ID ===
selection_id=$(echo "$selection" | awk '{print $1}')

# === Change default sink ===
wpctl set-default "$selection_id"

# === Verify change ===
new_sink_json=$(pw-metadata 0 'default.audio.sink' | sed -n "s/.* value:'\(.*\)' type.*/\1/p")
new_sink_name=$(echo "$new_sink_json" | jq -r '.name')

new_sink_id=$(pw-dump | jq -r --arg name "$new_sink_name" '
  .[] | select(.type == "PipeWire:Interface:Node") |
  .info.props | select(."node.name" == $name) |
  ."object.id"
')

if [ "$new_sink_id" != "$selection_id" ]; then
    notify-send "Failed to change audio sink" -u critical -t 2000
    exit 1
fi

# === Get friendly name for notification ===
new_sink_nick=$(pw-dump | jq -r --arg name "$new_sink_name" '
  .[] | select(.type == "PipeWire:Interface:Node") |
  .info.props | select(."node.name" == $name) |
  (."node.nick" // ."media.name" // ."node.description" // ."device.description" // $name)
')

notify-send "Changed default audio sink to $new_sink_nick" -t 2000

