#!/bin/bash
# ============================================================
# STOP-DASHBOARD.sh - Detiene los servers del dashboard
# ============================================================

echo ""
echo "Deteniendo dashboard (puertos 3200 y 8420)..."

for PORT in 3200 8420; do
    PIDS=$(lsof -ti:$PORT 2>/dev/null || ss -lptn "sport = :$PORT" 2>/dev/null | grep -oP 'pid=\K[0-9]+')
    for P in $PIDS; do
        kill -9 "$P" 2>/dev/null && echo "  Matado PID $P en puerto $PORT"
    done
done

echo ""
echo "Listo."
echo ""
