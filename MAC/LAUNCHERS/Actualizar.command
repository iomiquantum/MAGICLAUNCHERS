#!/bin/zsh
# ============================================================
# Actualizar.command - Descarga la ultima version del repo
# MAGICLAUNCHERS y reemplaza TODOS los launchers locales.
# Auto-detecta donde estan instalados.
# ============================================================
set -e

REPO_URL="https://github.com/iomiquantum/MAGICLAUNCHERS/archive/refs/heads/main.tar.gz"

clear
echo ""
echo "========================================"
echo "  Actualizar launchers desde GitHub"
echo "========================================"
echo ""

# Detectar estructura local
# Orden: estructura Miguel (Documents/...), Desktop custom, Desktop estandar
LAUNCHERS_DIR=""
ORQUESTADOR_DIR=""

# 1) Estructura de Miguel: Documents/CLAUDE Desarollo/CLAUDE LAUNCHERS /LAUNCHERS /
if [ -d "$HOME/Documents/CLAUDE Desarollo/CLAUDE LAUNCHERS /LAUNCHERS " ]; then
    LAUNCHERS_DIR="$HOME/Documents/CLAUDE Desarollo/CLAUDE LAUNCHERS /LAUNCHERS "
    ORQUESTADOR_DIR="$HOME/Documents/CLAUDE Desarollo/CLAUDE LAUNCHERS /ELIJE EL MODELO PARA LA TAREA "
# 2) Desktop estandar nuevo
elif [ -d "$HOME/Desktop/CLAUDE-LAUNCHERS" ]; then
    LAUNCHERS_DIR="$HOME/Desktop/CLAUDE-LAUNCHERS"
# 3) Desktop con espacio
elif [ -d "$HOME/Desktop/CLAUDE LAUNCHERS" ]; then
    if [ -d "$HOME/Desktop/CLAUDE LAUNCHERS/LAUNCHERS" ]; then
        LAUNCHERS_DIR="$HOME/Desktop/CLAUDE LAUNCHERS/LAUNCHERS"
        ORQUESTADOR_DIR="$HOME/Desktop/CLAUDE LAUNCHERS/ORQUESTADOR"
    else
        LAUNCHERS_DIR="$HOME/Desktop/CLAUDE LAUNCHERS"
    fi
fi

if [ -z "$LAUNCHERS_DIR" ]; then
    echo "ERROR: No encuentro donde estan instalados los launchers."
    echo ""
    echo "Rutas probadas:"
    echo "  ~/Documents/CLAUDE Desarollo/CLAUDE LAUNCHERS /LAUNCHERS /"
    echo "  ~/Desktop/CLAUDE-LAUNCHERS"
    echo "  ~/Desktop/CLAUDE LAUNCHERS"
    echo ""
    echo "Corre primero MAC/INSTALAR.command del repo."
    printf "Presiona Enter para cerrar. "
    read _
    exit 1
fi

echo "Launchers detectados en:"
echo "  $LAUNCHERS_DIR"
[ -n "$ORQUESTADOR_DIR" ] && echo "  $ORQUESTADOR_DIR"
echo ""
echo "Descargando ultima version desde GitHub..."

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

if ! curl -fsSL "$REPO_URL" | tar xz -C "$TMP"; then
    echo ""
    echo "ERROR: No pude descargar el repo."
    echo "  Verifica tu conexion a internet."
    echo "  Si el repo es privado, clonalo con 'git clone' primero."
    printf "Presiona Enter para cerrar. "
    read _
    exit 1
fi

REPO_DIR=$(find "$TMP" -maxdepth 1 -type d -name "MAGICLAUNCHERS-*" | head -1)

echo "Copiando .command a $LAUNCHERS_DIR..."
cp "$REPO_DIR/MAC/LAUNCHERS/"*.command "$LAUNCHERS_DIR/"
chmod +x "$LAUNCHERS_DIR/"*.command

if [ -n "$ORQUESTADOR_DIR" ] && [ -d "$ORQUESTADOR_DIR" ]; then
    echo "Copiando ORQUESTADOR a $ORQUESTADOR_DIR..."
    cp "$REPO_DIR/MAC/ORQUESTADOR/ORQUESTADOR.command" "$ORQUESTADOR_DIR/"
    chmod +x "$ORQUESTADOR_DIR/"*.command
fi

echo ""
echo "========================================"
echo "  ACTUALIZACION COMPLETA"
echo "========================================"
echo ""
echo "Launchers actualizados:"
ls -1 "$LAUNCHERS_DIR/" | grep -E '\.command$'
echo ""
echo "Las sesiones activas mantienen su nombre viejo."
echo "Para aplicar cambios, ejecuta:"
echo "  tmux kill-server"
echo "Y abre los launchers de nuevo."
echo ""
printf "Presiona Enter para cerrar. "
read _
