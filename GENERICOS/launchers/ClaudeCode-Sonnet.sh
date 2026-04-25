#!/bin/bash
CAFFEINATE=""
command -v caffeinate >/dev/null 2>&1 && CAFFEINATE="caffeinate -s"

COUNTER_FILE="$HOME/.claude-launchers/sonnet-counter"
mkdir -p "$HOME/.claude-launchers"
N=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
echo "$N" > "$COUNTER_FILE"
exec tmux new -s "SONNET-$N" "$CAFFEINATE claude --model claude-sonnet-4-6 --name SONNET-$N --dangerously-skip-permissions --rc"
