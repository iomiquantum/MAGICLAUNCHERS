#!/bin/bash
# Paridad con Mac: ORQUESTADOR.command (tu "MAESTRO")
# Sesion unica reutilizable + prompt de orquestador
if tmux has-session -t ORQUESTADOR 2>/dev/null; then
    exec tmux attach -t ORQUESTADOR
else
    exec tmux new -s ORQUESTADOR "claude --model claude-opus-4-6 --name ORQUESTADOR --append-system-prompt-file $HOME/.claude-launchers/orquestador-prompt.txt --dangerously-skip-permissions --rc"
fi
