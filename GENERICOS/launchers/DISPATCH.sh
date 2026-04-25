#!/bin/bash
echo "=== DISPATCH - Enviar tareas a sesiones Claude ==="
echo ""
echo "Sesiones activas:"
tmux ls 2>/dev/null || { echo "(ninguna)"; read; exit 1; }
echo ""

echo "Escribe la sesion destino (ej: HAIKU-1, OPUS-2, ORQUESTADOR):"
read SESSION

tmux has-session -t "$SESSION" 2>/dev/null || { echo "Sesion '$SESSION' no existe."; read; exit 1; }

echo "Escribe la tarea para $SESSION:"
read TAREA

tmux send-keys -t "$SESSION" "$TAREA" Enter
echo ""
echo "Tarea enviada a $SESSION."
echo ""
echo "Enviar a otra sesion? (s/n)"
read AGAIN
if [ "$AGAIN" = "s" ]; then
    exec "$0"
fi
