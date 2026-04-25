#!/bin/bash
# Paridad con Mac: ClaudeCode-Opus.command
# Modelo: claude-opus-4-6  (legacy, se mantiene por compatibilidad)
COUNTER_FILE="$HOME/.claude-launchers/opus-counter"
mkdir -p "$HOME/.claude-launchers"
N=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
echo "$N" > "$COUNTER_FILE"
exec tmux new -s "OPUS-$N" "claude --model claude-opus-4-6 --name OPUS-$N --dangerously-skip-permissions --rc"
