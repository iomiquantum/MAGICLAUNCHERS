#!/bin/bash
# ============================================================
# update-launchers.sh - Descarga ultima version del repo y
#   actualiza TODO: launchers + scripts auxiliares + template
# ============================================================
set -e

REPO_URL="https://github.com/iomiquantum/MAGICLAUNCHERS/archive/refs/heads/main.tar.gz"

DEST="$HOME/Desktop/CLAUDE-LAUNCHERS"
[ -d "$HOME/Desktop/CLAUDE LAUNCHERS" ] && [ ! -d "$DEST" ] && DEST="$HOME/Desktop/CLAUDE LAUNCHERS"

STATE="$HOME/.claude-launchers"
SCRIPTS="$STATE/scripts"
WS_TPL="$STATE/workspace-template"
mkdir -p "$STATE" "$SCRIPTS" "$WS_TPL"

if [ ! -d "$DEST" ]; then
    echo "ERROR: No existe $DEST"
    echo "Corre INSTALAR primero."
    exit 1
fi

echo ""
echo "== Actualizando todo desde GitHub =="
echo "  Destino launchers: $DEST"
echo "  Scripts auxiliares: $SCRIPTS"
echo "  Workspace template: $WS_TPL"
echo ""

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

if ! curl -fsSL "$REPO_URL" | tar xz -C "$TMP"; then
    echo "ERROR: No pude descargar el repo."
    exit 1
fi

REPO_DIR=$(find "$TMP" -maxdepth 1 -type d -name "MAGICLAUNCHERS-*" | head -1)
[ -z "$REPO_DIR" ] && { echo "ERROR: no encuentro repo descargado"; exit 1; }

# Detectar si estamos en WSL para usar launchers de WINDOWS/
if grep -qi microsoft /proc/version 2>/dev/null; then
    SRC_LAUNCHERS="$REPO_DIR/WINDOWS/launchers"
    echo "  Detectado WSL - usando WINDOWS/launchers/"
else
    SRC_LAUNCHERS="$REPO_DIR/GENERICOS/launchers"
    echo "  Usando GENERICOS/launchers/"
fi

# 1. Launchers principales
cp "$SRC_LAUNCHERS/"*.sh "$DEST/"
chmod +x "$DEST/"*.sh

# 2. Scripts de mantenimiento que van al Desktop
for s in set-machine-name.sh update-launchers.sh; do
    if [ -f "$REPO_DIR/GENERICOS/scripts/$s" ]; then
        cp "$REPO_DIR/GENERICOS/scripts/$s" "$DEST/"
        chmod +x "$DEST/$s"
    fi
done

# 3. Scripts que Claude invoca (van a ~/.claude-launchers/scripts/)
for s in crear-proyecto.sh listar-proyectos.sh promover-a-orca.sh archivar-proyecto.sh; do
    if [ -f "$REPO_DIR/GENERICOS/scripts/$s" ]; then
        cp "$REPO_DIR/GENERICOS/scripts/$s" "$SCRIPTS/"
        chmod +x "$SCRIPTS/$s"
    fi
done

# 4. CLAUDE.md template
if [ -f "$REPO_DIR/GENERICOS/workspace/CLAUDE.md" ]; then
    cp "$REPO_DIR/GENERICOS/workspace/CLAUDE.md" "$WS_TPL/"
fi

# 5. Mac: regenerar .command a partir de .sh si ya existen
if ls "$DEST/"*.command >/dev/null 2>&1; then
    for f in "$DEST/"*.sh; do
        base=$(basename "$f" .sh)
        cp "$f" "$DEST/${base}.command"
        chmod +x "$DEST/${base}.command"
    done
fi

echo ""
echo "LAUNCHERS:"
ls -1 "$DEST/" | grep -E '\.(sh|command)$'
echo ""
echo "SCRIPTS (para Claude):"
ls -1 "$SCRIPTS/" 2>/dev/null || echo "  (vacio)"
echo ""
echo "WORKSPACE TEMPLATE:"
ls -1 "$WS_TPL/" 2>/dev/null || echo "  (vacio)"
echo ""
echo "Las sesiones abiertas mantienen cwd viejo."
echo "Cierra con Kill-All y abre launchers de nuevo para activar."
echo ""
read -p "Presiona Enter para cerrar. " _
