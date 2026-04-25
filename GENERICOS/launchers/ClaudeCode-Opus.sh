#!/bin/bash
CAFFEINATE=""
command -v caffeinate >/dev/null 2>&1 && CAFFEINATE="caffeinate -s"

STATE="$HOME/.claude-launchers"
mkdir -p "$STATE"
COUNTER_FILE="$STATE/opus-counter"
N=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
echo "$N" > "$COUNTER_FILE"

if [ -f "$STATE/machine-name" ]; then
    MACHINE=$(cat "$STATE/machine-name" | tr -d '[:space:]')
else
    MACHINE=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "PC")
    MACHINE=$(echo "$MACHINE" | tr -c 'a-zA-Z0-9' '-' | cut -c1-15)
fi

NAME="OPUS-${MACHINE}-$N"
exec tmux new -s "$NAME" "$CAFFEINATE claude --model claude-opus-4-6 --name $NAME --dangerously-skip-permissions --rc"
