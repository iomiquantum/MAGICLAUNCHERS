#!/bin/bash
# ============================================================
# START-DASHBOARD.sh - Arranca dashboard-ORQUESTADOR en WSL
# Paridad con Mac START-DASHBOARD.command
# Puertos: 3200 (Node) + 8420 (Python usage)
# ============================================================

DASH_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$HOME/.claude-launchers/logs"
mkdir -p "$LOG_DIR"

# Mata instancias previas en esos puertos
for PORT in 3200 8420; do
    PIDS=$(lsof -ti:$PORT 2>/dev/null || ss -lptn "sport = :$PORT" 2>/dev/null | grep -oP 'pid=\K[0-9]+')
    for P in $PIDS; do kill -9 "$P" 2>/dev/null; done
done

echo ""
echo "  Claude Orchestrator"
echo "  ==================="
echo ""

# Usage server (Python)
if [ -f "$DASH_DIR/usage-server.py" ]; then
    nohup python3 "$DASH_DIR/usage-server.py" > "$LOG_DIR/usage.log" 2>&1 &
    echo "  Usage API en puerto 8420 (PID: $!)"
else
    echo "  (!) usage-server.py no encontrado"
fi

sleep 1

# Node orchestrator server
nohup node "$DASH_DIR/server.js" > "$LOG_DIR/orchestrator.log" 2>&1 &
echo "  Orchestrator en puerto 3200 (PID: $!)"

echo ""
echo "  Los servers corren en segundo plano."
echo "  Abre http://localhost:3200 en tu navegador Windows."
echo "  Logs: $LOG_DIR/"
echo ""
echo "  Para detenerlos: doble-click en Stop-Dashboard.bat"
echo ""
