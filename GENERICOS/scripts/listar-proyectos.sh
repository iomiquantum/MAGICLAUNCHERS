#!/bin/bash
# ============================================================
# listar-proyectos.sh - Lista proyectos de esta maquina
# en las 3 carpetas: PROYECTOS, ORQUESTADOS, ARCHIVO
# ============================================================

MACHINE=""
[ -f "$HOME/.claude-launchers/machine-name" ] && MACHINE=$(tr -d '[:space:]' < "$HOME/.claude-launchers/machine-name")
[ -z "$MACHINE" ] && MACHINE=$(hostname -s 2>/dev/null | tr -dc 'a-zA-Z0-9-' | cut -c1-15)

WORKSPACE="$HOME/Documents/PROYECTOS CLAUDE CODE/${MACHINE}"

if [ ! -d "$WORKSPACE" ]; then
    echo "(no hay workspace - abre algun launcher para inicializarlo)"
    exit 0
fi

print_section() {
    local LABEL="$1"
    local DIR="$2"
    echo ""
    echo "$LABEL"
    if [ ! -d "$DIR" ]; then
        echo "  (no existe)"
        return
    fi
    local FOUND=0
    while IFS= read -r d; do
        [ -z "$d" ] && continue
        FOUND=1
        local BASENAME=$(basename "$d")
        local META="$d/.proyecto.json"
        if [ -f "$META" ]; then
            # Extraer "name" del JSON sin python (parsing simple)
            local NAME=$(grep -o '"name"[^,}]*' "$META" | sed 's/.*"name"[^"]*"\([^"]*\)".*/\1/')
            local CREATED=$(grep -o '"created_at"[^,}]*' "$META" | sed 's/.*"created_at"[^"]*"\([^"]*\)".*/\1/')
            printf "  %-45s  %s\n" "$BASENAME" "$NAME"
        else
            printf "  %s\n" "$BASENAME"
        fi
    done < <(find "$DIR" -maxdepth 1 -mindepth 1 -type d | sort)
    [ $FOUND -eq 0 ] && echo "  (vacio)"
}

echo "==============================================="
echo "  Proyectos en $MACHINE"
echo "==============================================="

print_section "PROYECTOS LOCALES (PROY-XXX):" "$WORKSPACE/PROYECTOS"
print_section "ORQUESTADOS (ORCA-XXX):" "$WORKSPACE/ORQUESTADOS"
print_section "ARCHIVO:" "$WORKSPACE/ARCHIVO"
echo ""
