#!/bin/bash
# ============================================================
# install-launchers.sh - Copia los 8 launchers .sh a
#   ~/Desktop/CLAUDE-LAUNCHERS/ dentro de WSL
# Uso: install-launchers.sh <ruta-WSL-del-setup>
#   (la ruta /mnt/c/... de WINDOWS-CLAUDE-SETUP)
# ============================================================
set -e

SRC="${1:?Falta ruta al setup}"
DEST="$HOME/Desktop/CLAUDE-LAUNCHERS"
STATE="$HOME/.claude-launchers"

echo ""
echo "== Instalando launchers bash =="
echo "  Origen:  $SRC/launchers/"
echo "  Destino: $DEST/"

mkdir -p "$DEST" "$STATE"

cp "$SRC/launchers/"*.sh "$DEST/"
chmod +x "$DEST/"*.sh

# Helpers: set-machine-name y update-launchers (desde GENERICOS)
GEN_SCRIPTS="$SRC/../GENERICOS/scripts"
if [ -d "$GEN_SCRIPTS" ]; then
    cp "$GEN_SCRIPTS/set-machine-name.sh" "$DEST/" 2>/dev/null || true
    cp "$GEN_SCRIPTS/update-launchers.sh" "$DEST/" 2>/dev/null || true
    chmod +x "$DEST/set-machine-name.sh" "$DEST/update-launchers.sh" 2>/dev/null || true
fi

# Copia el prompt del orquestador a la ruta que esperan los launchers
cp "$SRC/config/orquestador-prompt.txt" "$STATE/orquestador-prompt.txt"

echo ""
echo "Launchers instalados:"
ls -1 "$DEST/"
echo ""
echo "Prompt orquestador: $STATE/orquestador-prompt.txt"
echo ""
