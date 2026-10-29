#!/bin/bash
set -u
cd "$(dirname "$0")"
export HOME=/tmp/starfront-v5-tests-home XDG_DATA_HOME=/tmp/starfront-v5-tests-data XDG_CONFIG_HOME=/tmp/starfront-v5-tests-config XDG_CACHE_HOME=/tmp/starfront-v5-tests-cache
mkdir -p "$HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" test-results/v5
status=0
for script in model_v5_test save_v5_test combat_v5_test ui_v5_test integration_v5_test ui_persistence_v5_test; do
  if test ! -f "tests/$script.gd"; then echo "NOT RUN: $script missing"; status=1; continue; fi
  echo "=== $script ==="
  timeout 180 godot --headless --path . --script "res://tests/$script.gd" >"test-results/v5/$script.log" 2>&1
  code=$?
  cat "test-results/v5/$script.log"
  if test "$code" -ne 0 || grep -Eq 'SCRIPT ERROR|Parse Error|Assertion failed' "test-results/v5/$script.log"; then status=1; echo "FAILED: $script (exit $code)"; fi
 done
exit "$status"
