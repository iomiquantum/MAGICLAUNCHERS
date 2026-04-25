#!/bin/bash
# ============================================================
# archivar-proyecto.sh - Mueve un proyecto a la carpeta ARCHIVO
# Uso: archivar-proyecto.sh /path/al/proyecto
# ============================================================
set -e

PROYECTO_PATH="${1:?Falta path. Uso: archivar-proyecto.sh /path/proyecto}"
[ ! -d "$PROYECTO_PATH" ] && { echo "ERROR: no existe $PROYECTO_PATH"; exit 1; }

PROYECTO_PATH=$(cd "$PROYECTO_PATH" && pwd)

MACHINE=""
[ -f "$HOME/.claude-launchers/machine-name" ] && MACHINE=$(tr -d '[:space:]' < "$HOME/.claude-launchers/machine-name")
[ -z "$MACHINE" ] && MACHINE=$(hostname -s 2>/dev/null | tr -dc 'a-zA-Z0-9-' | cut -c1-15)

WORKSPACE="$HOME/Documents/PROYECTOS CLAUDE CODE/${MACHINE}"
mkdir -p "$WORKSPACE/ARCHIVO"

NEW_PATH="$WORKSPACE/ARCHIVO/$(basename "$PROYECTO_PATH")"
if [ -e "$NEW_PATH" ]; then
    echo "ERROR: ya existe $NEW_PATH"
    exit 1
fi

mv "$PROYECTO_PATH" "$NEW_PATH"

# Actualizar metadata si existe
META="$NEW_PATH/.proyecto.json"
[ -f "$META" ] && sed -i.bak 's/"estado":[[:space:]]*"[^"]*"/"estado": "archivado"/' "$META" && rm -f "$META.bak"

echo "Archivado: $NEW_PATH"
