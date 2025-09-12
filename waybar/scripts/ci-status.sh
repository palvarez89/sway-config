#!/bin/bash

feed="http://epbr-cc-tray.s3-website.eu-west-2.amazonaws.com/"
xml=$(curl -s "$feed")

# Only match warehouse and data_frontend pipelines
filtered=$(echo "$xml" | grep -E 'epbr-(data-warehouse|data-frontend)-pipeline')

failures=$(echo "$filtered" | grep 'lastBuildStatus="Failure"')
building=$(echo "$filtered" | grep 'activity="Building"')

if [ -n "$building" ]; then
    icon="⏳"
elif [ -n "$failures" ]; then
    icon="❌"
else
    icon="✅"
fi

# Build tooltip with just the relevant projects
tooltip=$(echo "$filtered" | sed -n 's/.*Project name="\([^"]*\)".*lastBuildStatus="\([^"]*\)".*/\1 → \2/p')

# Output JSON for Waybar
echo "{\"text\": \"$icon\", \"tooltip\": \"${tooltip//$'\n'/\\n}\"}"
