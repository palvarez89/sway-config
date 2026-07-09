#!/bin/bash

# Get list of connected outputs from swaymsg with null separator
mapfile -d '' connected_outputs < <(swaymsg -t get_outputs | jq -r '.[] | select(.active) | "\(.make) \(.model)\'\n"')


# Define output patterns and their settings
# Format: "pattern|mode|scale|scale_filter"
output_configs=(
    "PHL 288E2|mode 3840x2160@60Hz|scale 1.2|scale_filter smart"
    "DELL SE2722HX|mode 1920x1080@60Hz|scale 0.8|scale_filter linear"
    "DELL S2725QC|mode 3840x2160@60Hz|scale 1.2|scale_filter linear"
)

# Generate output blocks
for output in "${connected_outputs[@]}"; do
    for config in "${output_configs[@]}"; do
        IFS='|' read -r pattern mode scale scale_filter <<< "$config"
        
        if [[ $output == *"$pattern"* ]]; then
            echo "output \"$output\" {"
            echo "    $mode"
            echo "    $scale"
            echo "    $scale_filter"
            echo "}"
            echo
            break
        fi
    done
done
