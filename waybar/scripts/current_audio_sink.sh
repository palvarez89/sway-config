#!/bin/sh

# Get the JSON string from pw-metadata
default_sink_json=$(pw-metadata 0 'default.audio.sink' | \
  sed -n "s/.* value:'\(.*\)' type.*/\1/p")

# Parse the default sink name
default_sink_name=$(echo "$default_sink_json" | jq -r '.name')

# Try multiple properties for a user-friendly label
default_sink_nick=$(pw-dump | jq -r --arg name "$default_sink_name" '
  .[] | select(.type == "PipeWire:Interface:Node") |
  .info.props | select(."node.name" == $name) |
  (."node.nick" // ."media.name" // ."node.description" // ."device.description" // $name)
')

# Optionally show profile type (for example: "Jabra Evolve2 65 (Pedro) [A2DP]")
profile=$(pw-dump | jq -r --arg name "$default_sink_name" '
  .[] | select(.type == "PipeWire:Interface:Node") |
  .info.props | select(."node.name" == $name) |
  (."api.bluez5.profile" // empty)
')


if [ -n "$profile" ]; then
  output="$default_sink_nick [$profile]"
else
  output="$default_sink_nick"
fi

# Trim to 16 characters
echo "${output:0:16}"
