#!/usr/bin/env sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  printf '%s\n' 'Godot 4.6.3 (standard) is required. Install it and set GODOT=/path/to/godot.' >&2
  exit 1
fi
exec "$GODOT" --path "$PWD" "$@"
