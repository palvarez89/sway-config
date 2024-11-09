#!/bin/sh

default_sink_name=$(pw-metadata 0 'default.audio.sink' | grep 'value' | sed "s/.* value:'//;s/' type:.*$//;" | jq .name)
echo "Currently selected \"$default_sink_name\""
default_sink_id=$(pw-dump Node Device | jq '.[].info.props|select(."node.name" == '" $default_sink_name "')|."object.id"')
other_sink_id=$(pw-dump Node Device | jq '.[].info.props|select(."api.alsa.pcm.stream" == "playback")|select(."object.id" != '" $default_sink_id "')| (."object.id"|tostring) + " " + ."node.nick"')

echo $default_sink_id
echo $other_sink_id | tr '"' '\n' | grep -v '^\s*$' | sort -n
selection=$(echo $other_sink_id | tr '"' '\n' | grep -v '^\s*$' | sort -n| rofi -dmenu -p="Select Audio Output")

echo "Selected \"$selection\""
selection=$(echo $selection | cut -d " " -f 1)
wpctl set-default $selection
new_sink_name=$(pw-metadata 0 'default.audio.sink' | grep 'value' | sed "s/.* value:'//;s/' type:.*$//;" | jq .name )
notify-send "Changed default audio sink to $new_sink_name"
