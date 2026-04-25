#!/bin/bash
STATE="$HOME/.claude-launchers"
mkdir -p "$STATE"

if [ -f "$STATE/machine-name" ]; then
    MACHINE=$(cat "$STATE/machine-name" | tr -d '[:space:]')
else
    MACHINE=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "PC")
    MACHINE=$(echo "$MACHINE" | tr -c 'a-zA-Z0-9' '-' | cut -c1-15)
fi

NAME="ORQUESTADOR-${MACHINE}"
if tmux has-session -t "$NAME" 2>/dev/null; then
    exec tmux attach -t "$NAME"
else
    exec tmux new -s "$NAME" "claude --model claude-opus-4-6 --name $NAME --append-system-prompt-file $STATE/orquestador-prompt.txt --dangerously-skip-permissions --rc"
fi
