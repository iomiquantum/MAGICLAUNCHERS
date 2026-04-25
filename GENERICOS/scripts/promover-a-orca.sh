#!/bin/bash
# ============================================================
# promover-a-orca.sh - Promueve un proyecto local a MASTERORCA
# Uso: promover-a-orca.sh /path/al/proyecto/local [brief-corto]
# Hace:
#   1. Asigna ID global ORCA-XXX (contador en repo MASTERORCA)
#   2. Mueve la carpeta de PROYECTOS/ a ORQUESTADOS/
#   3. Crea entrada en MASTERORCA repo con BRIEF.md
#   4. git push
# ============================================================
set -e

PROYECTO_PATH="${1:?Falta path del proyecto. Uso: promover-a-orca.sh /path/proyecto [brief]}"
BRIEF_TEXTO="${2:-}"

[ ! -d "$PROYECTO_PATH" ] && { echo "ERROR: $PROYECTO_PATH no existe"; exit 1; }

PROYECTO_PATH=$(cd "$PROYECTO_PATH" && pwd)  # absolute

MACHINE=""
[ -f "$HOME/.claude-launchers/machine-name" ] && MACHINE=$(tr -d '[:space:]' < "$HOME/.claude-launchers/machine-name")
[ -z "$MACHINE" ] && MACHINE=$(hostname -s 2>/dev/null | tr -dc 'a-zA-Z0-9-' | cut -c1-15)

WORKSPACE="$HOME/Documents/PROYECTOS CLAUDE CODE/${MACHINE}"

# 1) Verificar MASTERORCA clonado y autenticado
ORCA_REPO="$HOME/MASTERORCA"
if [ ! -d "$ORCA_REPO/.git" ]; then
    echo "ERROR: MASTERORCA no esta clonado en $ORCA_REPO"
    echo ""
    echo "Pasos para preparar:"
    echo "  1. gh auth login   (autenticar con GitHub)"
    echo "  2. cd ~ && git clone https://github.com/iomiquantum/MASTERORCA.git"
    echo "  3. Vuelve a correr este script"
    exit 1
fi

# 2) Sync con remote para tomar contador actualizado
cd "$ORCA_REPO"
git pull --quiet 2>&1 || { echo "ERROR: git pull fallo. Verifica autenticacion gh."; exit 1; }

# 3) ID global desde contador en el repo
COUNTER_FILE="$ORCA_REPO/.orca-counter"
N=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
ORCA_ID=$(printf "ORCA-%03d" "$N")

# 4) Slug del proyecto original (quitar prefix PROY-XXX-)
ORIG_BASENAME=$(basename "$PROYECTO_PATH")
SLUG=$(echo "$ORIG_BASENAME" | sed 's/^PROY-[0-9][0-9]*-//')
NEW_NAME="${ORCA_ID}-${SLUG}"

# 5) Mover carpeta local a ORQUESTADOS/
mkdir -p "$WORKSPACE/ORQUESTADOS"
NEW_LOCAL_PATH="$WORKSPACE/ORQUESTADOS/$NEW_NAME"
if [ -e "$NEW_LOCAL_PATH" ]; then
    echo "ERROR: ya existe $NEW_LOCAL_PATH"
    exit 1
fi
mv "$PROYECTO_PATH" "$NEW_LOCAL_PATH"

# 6) Actualizar metadata local
META="$NEW_LOCAL_PATH/.proyecto.json"
if [ -f "$META" ]; then
    # Reescribir agregando campos orca (sed simple, no perfect pero funciona)
    NOW=$(date -u +%FT%TZ)
    cat > "$META.new" <<EOF
{
  "id": "$ORCA_ID",
  "id_local_origen": "$(basename "$PROYECTO_PATH" | grep -o 'PROY-[0-9]*' || echo '')",
  "name": "$(grep -o '"name"[^,}]*' "$META" | sed 's/.*"name"[^"]*"\([^"]*\)".*/\1/')",
  "slug": "$SLUG",
  "machine": "$MACHINE",
  "estado": "orquestado",
  "promovido_at": "$NOW",
  "masterorca_path": "PROYECTOS/$NEW_NAME"
}
EOF
    mv "$META.new" "$META"
fi

# 7) Crear entrada en repo MASTERORCA
ORCA_PROY_DIR="$ORCA_REPO/PROYECTOS/$NEW_NAME"
mkdir -p "$ORCA_PROY_DIR/ENTREGABLES"

# BRIEF.md (con texto opcional pasado como arg2 o template)
if [ -n "$BRIEF_TEXTO" ]; then
    cat > "$ORCA_PROY_DIR/BRIEF.md" <<EOF
# ${NEW_NAME}

> Promovido desde \`$MACHINE\` el $(date +%Y-%m-%d) por origen local.

## Brief
$BRIEF_TEXTO

## Origen
- Maquina: $MACHINE
- Path local: \`~/Documents/PROYECTOS CLAUDE CODE/${MACHINE}/ORQUESTADOS/${NEW_NAME}/\`

## Status
Recien promovido. Esperando ANALISIS.md del Orquestador.
EOF
else
    cat > "$ORCA_PROY_DIR/BRIEF.md" <<EOF
# ${NEW_NAME}

> Promovido desde \`$MACHINE\` el $(date +%Y-%m-%d).

## Brief
(Sin descripcion. Edita este archivo o pide al Orquestador que lo
genere a partir del trabajo previo en la carpeta local.)

## Origen
- Maquina: $MACHINE
- Path local: \`~/Documents/PROYECTOS CLAUDE CODE/${MACHINE}/ORQUESTADOS/${NEW_NAME}/\`

## Status
Recien promovido. Esperando ANALISIS.md del Orquestador.
EOF
fi

# 8) Guardar contador y push
echo "$N" > "$COUNTER_FILE"
git add . >/dev/null 2>&1
git commit -m "[$ORCA_ID] Promover proyecto: $NEW_NAME (origen: $MACHINE)" >/dev/null 2>&1
git push --quiet 2>&1 || { echo "ERROR: git push fallo. Verifica gh auth."; exit 1; }

# 9) Reporte
echo "=================================================="
echo "  PROMOCION EXITOSA"
echo "=================================================="
echo ""
echo "  ID asignado:        $ORCA_ID"
echo "  Carpeta local:      $NEW_LOCAL_PATH"
echo "  Carpeta MASTERORCA: $ORCA_PROY_DIR"
echo "  GitHub:             https://github.com/iomiquantum/MASTERORCA/tree/main/PROYECTOS/$NEW_NAME"
echo ""
echo "Siguientes pasos sugeridos:"
echo "  - Que el Orquestador lea BRIEF.md y genere ANALISIS.md"
echo "  - El Orquestador asigna tareas a maquinas del cluster"
echo "  - Workers ejecutan en paralelo"
echo ""
