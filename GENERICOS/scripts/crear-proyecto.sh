#!/bin/bash
# ============================================================
# crear-proyecto.sh - Crea un proyecto local con ID auto
# Uso: crear-proyecto.sh "nombre del proyecto"
# Output: imprime la ruta absoluta del proyecto creado
# ============================================================
set -e

NOMBRE="${1:?Falta nombre del proyecto. Uso: crear-proyecto.sh \"nombre\"}"

# Detectar machine
MACHINE=""
[ -f "$HOME/.claude-launchers/machine-name" ] && MACHINE=$(tr -d '[:space:]' < "$HOME/.claude-launchers/machine-name")
[ -z "$MACHINE" ] && MACHINE=$(hostname -s 2>/dev/null | tr -dc 'a-zA-Z0-9-' | cut -c1-15)
[ -z "$MACHINE" ] && MACHINE="MACHINE"

# Slug del nombre (lowercase, guiones, max 30)
SLUG=$(echo "$NOMBRE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -dc 'a-z0-9-' | sed 's/--*/-/g; s/^-//; s/-$//' | cut -c1-30)
[ -z "$SLUG" ] && SLUG="sin-nombre"

# ID auto-incremental por máquina
COUNTER_FILE="$HOME/.claude-launchers/proyecto-counter"
mkdir -p "$HOME/.claude-launchers"
N=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
echo "$N" > "$COUNTER_FILE"
ID=$(printf "PROY-%03d" "$N")

WORKSPACE="$HOME/Documents/PROYECTOS CLAUDE CODE/${MACHINE}"
mkdir -p "$WORKSPACE/PROYECTOS"
PROJ_DIR="$WORKSPACE/PROYECTOS/${ID}-${SLUG}"
mkdir -p "$PROJ_DIR"

# Metadata
cat > "$PROJ_DIR/.proyecto.json" <<EOF
{
  "id": "$ID",
  "name": "$NOMBRE",
  "slug": "$SLUG",
  "machine": "$MACHINE",
  "created_at": "$(date -u +%FT%TZ)",
  "estado": "local"
}
EOF

# README inicial vacio para que VS Code/Finder reconozcan la carpeta
cat > "$PROJ_DIR/README.md" <<EOF
# $NOMBRE

ID: \`$ID\`
Maquina: \`$MACHINE\`
Estado: local

## Notas

(Lo que vayas haciendo aqui se guarda en este proyecto. Cuando estes
listo para distribuirlo entre maquinas, pide al asistente que lo
\"promueva a ORCA\".)
EOF

echo "$PROJ_DIR"
