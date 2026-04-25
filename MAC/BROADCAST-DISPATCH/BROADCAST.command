#!/bin/zsh
echo "=== BROADCAST - Enviar tarea a TODAS las sesiones ==="
echo ""
echo "Sesiones activas:"
tmux ls 2>/dev/null || { echo "(ninguna)"; read; exit 1; }
echo ""

echo "Escribe la tarea para TODAS las sesiones:"
read TAREA

for SESSION in $(tmux ls -F '#{session_name}' 2>/dev/null); do
    tmux send-keys -t "$SESSION" "$TAREA" Enter
    echo "Enviado a: $SESSION"
done

echo ""
echo "Tarea enviada a todas las sesiones."
echo "Presiona Enter para cerrar."
read
