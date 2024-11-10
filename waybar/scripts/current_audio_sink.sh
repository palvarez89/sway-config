#!/bin/sh

default_sink_name=$(pw-metadata 0 'default.audio.sink' | grep 'value' | sed "s/.* value:'//;s/' type:.*$//;" | jq .name)
default_sink_nick=$(pw-dump Node Device | jq '.[].info.props|select(."node.name" == '" $default_sink_name "')|."node.nick"')
echo $default_sink_nick
