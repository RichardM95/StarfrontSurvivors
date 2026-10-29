#!/bin/sh
export XDG_CONFIG_HOME=/tmp/godot-android-tools/config XDG_DATA_HOME=/tmp/starfront-v4-preview XDG_CACHE_HOME=/tmp/godot-android-tools/cache
exec /usr/local/bin/godot --path /workspace/scratch/ee0b12867f8b/starfront-survivors --resolution 960x600 > /tmp/v4-gui.log 2>&1
