#!/bin/zsh

# Kill previous instances
lsof -ti:3200 | xargs kill -9 2>/dev/null
lsof -ti:8420 | xargs kill -9 2>/dev/null

DASH_DIR="$(dirname "$0")"
LOG_DIR="$HOME/.claude-launchers/logs"
mkdir -p "$LOG_DIR"

echo ""
echo "  Claude Orchestrator"
echo "  ==================="
echo ""

# Start usage dashboard (Python) in background
USAGE_SERVER=$(find "$HOME" -maxdepth 3 -name "server.py" -path "*claude-usage*" 2>/dev/null | head -1)
if [ -n "$USAGE_SERVER" ]; then
  nohup python3 "$USAGE_SERVER" > "$LOG_DIR/usage.log" 2>&1 &
  echo "  Usage API en puerto 8420 (PID: $!)"
else
  echo "  (!) Usage dashboard no encontrado"
fi

sleep 1

# Start Node server in background
nohup node "$DASH_DIR/server.js" > "$LOG_DIR/orchestrator.log" 2>&1 &
NODE_PID=$!
echo "  Orchestrator en puerto 3200 (PID: $NODE_PID)"
echo ""
echo "  Los servers corren en segundo plano."
echo "  Puedes cerrar esta terminal sin problemas."
echo ""
echo "  Para detener todo: doble clic en STOP-DASHBOARD.command"
echo ""

# Open browser
open http://localhost:3200

echo "  Listo. Puedes cerrar esta ventana."
