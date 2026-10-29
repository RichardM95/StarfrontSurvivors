#!/bin/sh
export XDG_CONFIG_HOME=/tmp/godot-android-tools/config XDG_DATA_HOME=/tmp/starfront-ui41-preview XDG_CACHE_HOME=/tmp/godot-android-tools/cache
godot --headless --path /workspace/scratch/ee0b12867f8b/starfront-survivors --editor --import --quit >/workspace/scratch/ee0b12867f8b/starfront-survivors/test-results/ui/import.log 2>&1
exec godot --path /workspace/scratch/ee0b12867f8b/starfront-survivors --resolution 1120x700 --audio-driver Dummy --script res://tests/ui41_preview.gd >/workspace/scratch/ee0b12867f8b/starfront-survivors/test-results/ui/gui.log 2>&1
