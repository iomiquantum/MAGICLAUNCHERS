#!/bin/bash
CAFFEINATE=""
command -v caffeinate >/dev/null 2>&1 && CAFFEINATE="caffeinate -s"

if tmux has-session -t ORQUESTADOR 2>/dev/null; then
    exec tmux attach -t ORQUESTADOR
else
    exec tmux new -s ORQUESTADOR "$CAFFEINATE claude --model claude-opus-4-6 --name ORQUESTADOR --append-system-prompt-file $HOME/.claude-launchers/orquestador-prompt.txt --dangerously-skip-permissions --rc"
fi
