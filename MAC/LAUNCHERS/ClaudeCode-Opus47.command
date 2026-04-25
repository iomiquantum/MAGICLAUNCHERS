#!/bin/zsh
COUNTER_FILE="$HOME/.claude-launchers/opus47-counter"
mkdir -p "$HOME/.claude-launchers"
N=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
echo "$N" > "$COUNTER_FILE"
exec tmux new -s "OPUS47-$N" "caffeinate -s claude --model claude-opus-4-7 --name OPUS47-$N --dangerously-skip-permissions --rc"
