#!/bin/sh

default_sink_name=$(pw-metadata 0 'default.audio.sink' | grep 'value' | sed "s/.* value:'//;s/' type:.*$//;" | jq .name)
echo "Currently selected \"$default_sink_name\""
default_sink_id=$(pw-dump Node Device | jq '.[].info.props|select(."node.name" == '" $default_sink_name "')|."object.id"')
other_sink_id=$(pw-dump Node Device | jq '.[].info.props|select(."api.alsa.pcm.stream" == "playback")|select(."object.id" != '" $default_sink_id "')| (."object.id"|tostring) + " " + ."node.nick"')

echo $default_sink_id
echo $other_sink_id | tr '"' '\n' | grep -v '^\s*$' | sort -n
selection=$(echo $other_sink_id | tr '"' '\n' | grep -v '^\s*$' | sort -n| rofi -dmenu -p "Select Audio Output")

echo "Selected \"$selection\""
selection=$(echo $selection | cut -d " " -f 1)
if [ x$selection == "x" ]; then
    exit 1
fi
wpctl set-default $selection
new_sink_name=$(pw-metadata 0 'default.audio.sink' | grep 'value' | sed "s/.* value:'//;s/' type:.*$//;" | jq .name )
new_sink_id=$(pw-dump Node Device | jq '.[].info.props|select(."node.name" == '" $new_sink_name "')|."object.id"')
if [ $new_sink_id != $selection ]; then
    notify-send "Failed to change audio sink" -u critical -t 2000
else
    new_sink_nick=$(pw-dump Node Device | jq '.[].info.props|select(."node.name" == '" $new_sink_name "')|."node.nick"')
    notify-send "Changed default audio sink to $new_sink_nick" -t 2000
fi
