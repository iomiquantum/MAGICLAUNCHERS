#!/bin/zsh
STATE="$HOME/.claude-launchers"
mkdir -p "$STATE"

if [ -f "$STATE/machine-name" ]; then
    MACHINE=$(cat "$STATE/machine-name" | tr -d '[:space:]')
else
    MACHINE=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "MAC")
    MACHINE=$(echo "$MACHINE" | tr -c 'a-zA-Z0-9' '-' | cut -c1-15)
fi

NAME="ORQUESTADOR-${MACHINE}"
WORKSPACE="$HOME/Documents/PROYECTOS CLAUDE CODE/${MACHINE}"
mkdir -p "$WORKSPACE/PROYECTOS" "$WORKSPACE/ORQUESTADOS" "$WORKSPACE/ARCHIVO"
[ ! -f "$WORKSPACE/CLAUDE.md" ] && [ -f "$STATE/workspace-template/CLAUDE.md" ] && cp "$STATE/workspace-template/CLAUDE.md" "$WORKSPACE/"
printf '\033]0;%s\007\033]2;%s\007' "$NAME" "$NAME"
if tmux has-session -t "$NAME" 2>/dev/null; then
    exec tmux attach -t "$NAME"
else
    exec tmux new -s "$NAME" -c "$WORKSPACE" "caffeinate -s claude --model claude-opus-4-6 --name $NAME --append-system-prompt-file $STATE/orquestador-prompt.txt --dangerously-skip-permissions --rc"
fi
