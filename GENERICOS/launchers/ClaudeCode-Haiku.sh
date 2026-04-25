#!/bin/bash
CAFFEINATE=""
command -v caffeinate >/dev/null 2>&1 && CAFFEINATE="caffeinate -s"

COUNTER_FILE="$HOME/.claude-launchers/haiku-counter"
mkdir -p "$HOME/.claude-launchers"
N=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
echo "$N" > "$COUNTER_FILE"
exec tmux new -s "HAIKU-$N" "$CAFFEINATE claude --model claude-haiku-4-5-20251001 --name HAIKU-$N --dangerously-skip-permissions --rc"
