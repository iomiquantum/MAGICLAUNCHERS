#!/bin/bash
# Paridad con Mac: KILL-ALL.command
echo "Sesiones tmux activas:"
tmux ls 2>/dev/null || echo "(ninguna)"
echo ""
echo "Matando todas las sesiones..."
tmux kill-server 2>/dev/null
echo "Listo. Todas las sesiones cerradas."
echo ""
echo "Presiona Enter para cerrar."
read
