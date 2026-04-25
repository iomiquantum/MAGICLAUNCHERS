#!/bin/zsh
echo ""
echo "  Deteniendo Claude Orchestrator..."
echo ""

# Kill Node (port 3200)
PIDS=$(lsof -ti:3200 2>/dev/null)
if [ -n "$PIDS" ]; then
  echo "$PIDS" | xargs kill -9 2>/dev/null
  echo "  Orchestrator detenido"
else
  echo "  Orchestrator no estaba corriendo"
fi

# Kill Python (port 8420)
PIDS=$(lsof -ti:8420 2>/dev/null)
if [ -n "$PIDS" ]; then
  echo "$PIDS" | xargs kill -9 2>/dev/null
  echo "  Usage API detenida"
else
  echo "  Usage API no estaba corriendo"
fi

echo ""
echo "  Todo detenido."
echo "  Presiona Enter para cerrar."
read
