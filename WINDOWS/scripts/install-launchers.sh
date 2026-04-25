#!/bin/bash
# ============================================================
# install-launchers.sh - Instala todo el setup en WSL/Ubuntu:
#   - Launchers .sh a ~/Desktop/CLAUDE-LAUNCHERS/
#   - Scripts auxiliares a ~/.claude-launchers/scripts/
#   - CLAUDE.md template a ~/.claude-launchers/workspace-template/
#   - Prompt del orquestador
# Uso: install-launchers.sh <ruta-WSL-del-setup>
# ============================================================
set -e

SRC="${1:?Falta ruta al setup}"
DEST="$HOME/Desktop/CLAUDE-LAUNCHERS"
STATE="$HOME/.claude-launchers"
SCRIPTS="$STATE/scripts"
WS_TPL="$STATE/workspace-template"

echo ""
echo "== Instalando setup MASTERORCA-ready =="
echo "  Launchers:       $DEST/"
echo "  Scripts:         $SCRIPTS/"
echo "  WS template:     $WS_TPL/"

mkdir -p "$DEST" "$STATE" "$SCRIPTS" "$WS_TPL"

# 1. Launchers principales
cp "$SRC/launchers/"*.sh "$DEST/"
chmod +x "$DEST/"*.sh

# 2. Scripts auxiliares (desde GENERICOS, son universales)
GEN_SCRIPTS="$SRC/../GENERICOS/scripts"
if [ -d "$GEN_SCRIPTS" ]; then
    # Scripts de mantenimiento (en Desktop para que Renombrar/Actualizar/etc funcionen)
    cp "$GEN_SCRIPTS/set-machine-name.sh" "$DEST/" 2>/dev/null || true
    cp "$GEN_SCRIPTS/update-launchers.sh" "$DEST/" 2>/dev/null || true
    chmod +x "$DEST/set-machine-name.sh" "$DEST/update-launchers.sh" 2>/dev/null || true

    # Scripts que Claude invoca (NO van al Desktop, van a $SCRIPTS)
    for s in crear-proyecto.sh listar-proyectos.sh promover-a-orca.sh archivar-proyecto.sh; do
        if [ -f "$GEN_SCRIPTS/$s" ]; then
            cp "$GEN_SCRIPTS/$s" "$SCRIPTS/"
            chmod +x "$SCRIPTS/$s"
        fi
    done
fi

# 3. CLAUDE.md template para workspace
GEN_WS="$SRC/../GENERICOS/workspace"
if [ -f "$GEN_WS/CLAUDE.md" ]; then
    cp "$GEN_WS/CLAUDE.md" "$WS_TPL/"
fi

# 4. Prompt del orquestador
cp "$SRC/config/orquestador-prompt.txt" "$STATE/orquestador-prompt.txt"

echo ""
echo "Launchers en Desktop:"
ls -1 "$DEST/" | grep -E '\.sh$'
echo ""
echo "Scripts auxiliares para Claude en $SCRIPTS:"
ls -1 "$SCRIPTS/"
echo ""
echo "Workspace template:"
ls -1 "$WS_TPL/"
echo ""
