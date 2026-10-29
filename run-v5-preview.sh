#!/bin/sh
export XDG_DATA_HOME=/tmp/starfront-v5-gui-data XDG_CONFIG_HOME=/tmp/starfront-v5-gui-config XDG_CACHE_HOME=/tmp/starfront-v5-gui-cache
exec godot --path /workspace/scratch/ee0b12867f8b/starfront-survivors --resolution 1200x675 --audio-driver Dummy -- --v5-preview=bridge >/workspace/scratch/ee0b12867f8b/starfront-survivors/test-results/v5/gui.log 2>&1
