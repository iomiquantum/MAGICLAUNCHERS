#!/bin/bash
# ============================================================
# install-dashboard.sh - Copia el dashboard-ORQUESTADOR a
#   ~/Desktop/CLAUDE-LAUNCHERS/dashboard/ dentro de WSL
# Uso: install-dashboard.sh <ruta-WSL-del-setup>
# ============================================================
set -e

SRC="${1:?Falta ruta al setup}"
DEST="$HOME/Desktop/CLAUDE-LAUNCHERS/dashboard"

echo ""
echo "== Instalando dashboard-ORQUESTADOR =="
echo "  Origen:  $SRC/dashboard/"
echo "  Destino: $DEST/"

mkdir -p "$DEST"
cp -r "$SRC/dashboard/." "$DEST/"
chmod +x "$DEST/"*.sh 2>/dev/null || true

echo ""
echo "Dashboard instalado:"
ls -1 "$DEST/"
echo ""
