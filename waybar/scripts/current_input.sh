#!/bin/sh

default_source_json=$(pw-metadata 0 'default.audio.source' | sed -n "s/.* value:'\(.*\)' type.*/\1/p")
default_source_name=$(echo "$default_source_json" | jq -r '.name')

mic_name=$(pw-dump | jq -r --arg name "$default_source_name" '
  .[] | select(.type == "PipeWire:Interface:Node") |
  .info.props | select(."node.name" == $name) |
  (."node.nick" // ."media.name" // ."node.description" // ."device.description" // $name)
')

# Output JSON for Waybar
printf '{"text": "🎤", "tooltip": "%s"}\n' "$mic_name"

