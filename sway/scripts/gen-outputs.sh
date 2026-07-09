#!/bin/bash

# Get list of connected outputs from swaymsg with null separator
echo "DEBUG: Fetching outputs from swaymsg..." >&2
mapfile -d '' connected_outputs < <(swaymsg -t get_outputs | jq -r '.[] | select(.active) | "\(.make) \(.model)\n"')

for i in "${!connected_outputs[@]}"; do
    echo "DEBUG: Output $i: '${connected_outputs[$i]}'" >&2
done

# Define output patterns and their settings
# Format: "pattern|mode|scale|scale_filter"
output_configs=(
    "PHL 288E2|mode 3840x2160@60Hz|scale 1.2|scale_filter smart"
    "DELL SE2722HX|mode 1920x1080@60Hz|scale 0.8|scale_filter linear"
    "DELL S2725QC|mode 3840x2160@60Hz|scale 1.2|scale_filter linear"
)


# Generate output blocks
for output in "${connected_outputs[@]}"; do
    echo "DEBUG: Checking output: '$output'" >&2
    matched=0
    for config in "${output_configs[@]}"; do
        IFS='|' read -r pattern mode scale scale_filter <<< "$config"
        echo "DEBUG:   Trying pattern: '$pattern'" >&2
        
        if [[ $output == *"$pattern"* ]]; then
            echo "DEBUG:   MATCHED!" >&2
            echo "output \"$output\" {"
            echo "    $mode"
            echo "    $scale"
            echo "    $scale_filter"
            echo "}"
            echo
            matched=1
            break
        fi
    done
    if [[ $matched -eq 0 ]]; then
        echo "DEBUG:   No match found for '$output'" >&2
    fi
done
