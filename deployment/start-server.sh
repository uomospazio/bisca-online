#!/bin/bash
set -euo pipefail
godot --headless --path /app -- --server --websocket &
game_pid=$!
nginx -c /app/nginx.conf -g 'daemon off;' &
proxy_pid=$!
trap 'kill "$game_pid" "$proxy_pid" 2>/dev/null || true' EXIT TERM INT
wait -n "$game_pid" "$proxy_pid"
exit 1
