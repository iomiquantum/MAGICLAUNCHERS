#!/bin/bash
# Universal - Mac (caffeinate) y Linux (sin caffeinate)
CAFFEINATE=""
command -v caffeinate >/dev/null 2>&1 && CAFFEINATE="caffeinate -s"

COUNTER_FILE="$HOME/.claude-launchers/opus-counter"
mkdir -p "$HOME/.claude-launchers"
N=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
echo "$N" > "$COUNTER_FILE"
exec tmux new -s "OPUS-$N" "$CAFFEINATE claude --model claude-opus-4-6 --name OPUS-$N --dangerously-skip-permissions --rc"
