#!/bin/zsh
STATE="$HOME/.claude-launchers"
mkdir -p "$STATE"
COUNTER_FILE="$STATE/sonnet-counter"
N=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
echo "$N" > "$COUNTER_FILE"

if [ -f "$STATE/machine-name" ]; then
    MACHINE=$(cat "$STATE/machine-name" | tr -d '[:space:]')
else
    MACHINE=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "MAC")
    MACHINE=$(echo "$MACHINE" | tr -c 'a-zA-Z0-9' '-' | cut -c1-15)
fi

NAME="SONNET-${MACHINE}-$N"
WORKSPACE="$HOME/Documents/PROYECTOS CLAUDE CODE/${MACHINE}"
mkdir -p "$WORKSPACE/PROYECTOS" "$WORKSPACE/ORQUESTADOS" "$WORKSPACE/ARCHIVO"
[ ! -f "$WORKSPACE/CLAUDE.md" ] && [ -f "$STATE/workspace-template/CLAUDE.md" ] && cp "$STATE/workspace-template/CLAUDE.md" "$WORKSPACE/"
printf '\033]0;%s\007\033]2;%s\007' "$NAME" "$NAME"
exec tmux new -s "$NAME" -c "$WORKSPACE" "caffeinate -s claude --model claude-sonnet-4-6 --name $NAME --dangerously-skip-permissions --rc"
