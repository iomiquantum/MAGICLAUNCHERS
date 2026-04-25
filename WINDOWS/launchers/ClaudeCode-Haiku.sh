#!/bin/bash
STATE="$HOME/.claude-launchers"
mkdir -p "$STATE"
COUNTER_FILE="$STATE/haiku-counter"
N=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
echo "$N" > "$COUNTER_FILE"

if [ -f "$STATE/machine-name" ]; then
    MACHINE=$(cat "$STATE/machine-name" | tr -d '[:space:]')
else
    MACHINE=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "PC")
    MACHINE=$(echo "$MACHINE" | tr -c 'a-zA-Z0-9' '-' | cut -c1-15)
fi

NAME="HAIKU-${MACHINE}-$N"
PROJECTS_DIR="$HOME/Documents/PROYECTOS CLAUDE CODE/${MACHINE}/HAIKU"
mkdir -p "$PROJECTS_DIR"
printf '\033]0;%s\007\033]2;%s\007' "$NAME" "$NAME"
exec tmux new -s "$NAME" -c "$PROJECTS_DIR" "claude --model claude-haiku-4-5-20251001 --name $NAME --dangerously-skip-permissions --rc"
