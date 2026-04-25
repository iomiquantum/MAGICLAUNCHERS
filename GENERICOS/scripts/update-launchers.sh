#!/bin/bash
# ============================================================
# update-launchers.sh - Actualiza los launchers instalados
# Descarga la version mas reciente del repo MAGICLAUNCHERS
# y reemplaza los .sh en ~/Desktop/CLAUDE-LAUNCHERS/
# ============================================================
set -e

REPO_URL="https://github.com/iomiquantum/MAGICLAUNCHERS/archive/refs/heads/main.tar.gz"

# Detectar destino
DEST="$HOME/Desktop/CLAUDE-LAUNCHERS"
[ -d "$HOME/Desktop/CLAUDE LAUNCHERS" ] && [ ! -d "$DEST" ] && DEST="$HOME/Desktop/CLAUDE LAUNCHERS"

if [ ! -d "$DEST" ]; then
    echo "ERROR: No existe $DEST"
    echo "Corre INSTALAR primero."
    exit 1
fi

echo ""
echo "== Actualizando launchers =="
echo "  Destino: $DEST"
echo ""
echo "Descargando ultima version de GitHub..."

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

if ! curl -fsSL "$REPO_URL" | tar xz -C "$TMP"; then
    echo "ERROR: No pude descargar el repo."
    echo "  Verifica tu conexion a internet."
    echo "  Si el repo es privado, tendras que clonarlo manualmente."
    exit 1
fi

REPO_DIR=$(find "$TMP" -maxdepth 1 -type d -name "MAGICLAUNCHERS-*" | head -1)
if [ -z "$REPO_DIR" ]; then
    echo "ERROR: No encuentro el repo descargado."
    exit 1
fi

# Usar los launchers de GENERICOS (que son universales Mac+Linux+WSL)
SRC_LAUNCHERS="$REPO_DIR/GENERICOS/launchers"
SRC_SCRIPTS="$REPO_DIR/GENERICOS/scripts"

# En Windows/WSL, los .sh de WINDOWS/ no tienen caffeinate - usar esos
if grep -qi microsoft /proc/version 2>/dev/null; then
    SRC_LAUNCHERS="$REPO_DIR/WINDOWS/launchers"
    echo "  Detectado WSL - usando launchers de WINDOWS/"
else
    echo "  Usando launchers universales de GENERICOS/"
fi

cp "$SRC_LAUNCHERS/"*.sh "$DEST/"
chmod +x "$DEST/"*.sh

# Actualizar helpers tambien
cp "$SRC_SCRIPTS/set-machine-name.sh" "$DEST/" 2>/dev/null || true
cp "$SRC_SCRIPTS/update-launchers.sh" "$DEST/" 2>/dev/null || true
chmod +x "$DEST/set-machine-name.sh" "$DEST/update-launchers.sh" 2>/dev/null || true

# Si existen .command (Mac), regenerarlos
if ls "$DEST/"*.command >/dev/null 2>&1; then
    for f in "$DEST/"*.sh; do
        base=$(basename "$f" .sh)
        cp "$f" "$DEST/${base}.command"
        chmod +x "$DEST/${base}.command"
    done
fi

echo ""
echo "Launchers actualizados:"
ls -1 "$DEST/" | grep -E '\.(sh|command)$'
echo ""
echo "Las sesiones tmux ya abiertas siguen con su nombre viejo."
echo "Cierralas con Kill-All.bat y abre launchers nuevos para el cambio."
echo ""
read -p "Presiona Enter para cerrar. " _
