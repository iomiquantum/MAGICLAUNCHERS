#!/bin/zsh
# ============================================================
# Renombrar-Mac.command - Asigna un nombre corto a esta Mac
# Guarda en ~/.claude-launchers/machine-name
# Los launchers lo usan: OPUS47-NOMBRE-1, SONNET-NOMBRE-1, etc.
# ============================================================

STATE="$HOME/.claude-launchers"
mkdir -p "$STATE"
FILE="$STATE/machine-name"

CURRENT="(ninguno - usa hostname automatico)"
[ -f "$FILE" ] && CURRENT=$(cat "$FILE" | tr -d '[:space:]')

AUTO=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "MAC")
AUTO=$(echo "$AUTO" | tr -c 'a-zA-Z0-9' '-' | cut -c1-15)

clear
echo ""
echo "========================================"
echo "  Renombrar esta Mac"
echo "========================================"
echo ""
echo "Nombre actual:       $CURRENT"
echo "Hostname automatico: $AUTO"
echo ""
echo "Escribe nombre corto (ej: MAC, IOMI, CASA, STUDIO)"
echo "  - Max 15 caracteres"
echo "  - Solo letras, numeros, guiones"
echo "  - Enter vacio = borrar custom, usar hostname"
echo ""
printf "Nuevo nombre: "
read NEW

NEW=$(echo "$NEW" | tr -c 'a-zA-Z0-9-' '' | cut -c1-15)
NEW=$(echo "$NEW" | sed 's/--*/-/g; s/^-//; s/-$//')

if [ -z "$NEW" ]; then
    rm -f "$FILE"
    echo ""
    echo "Nombre custom borrado."
    echo "Los launchers usaran el hostname: $AUTO"
else
    echo "$NEW" > "$FILE"
    echo ""
    echo "Nombre guardado: $NEW"
    echo ""
    echo "Tus proximos launchers abriran:"
    echo "  OPUS47-${NEW}-1"
    echo "  SONNET-${NEW}-1"
    echo "  HAIKU-${NEW}-1"
    echo "  ORQUESTADOR-${NEW}"
fi

echo ""
echo "Las sesiones ya abiertas mantienen su nombre viejo."
echo "Para aplicar el cambio: cierra con 'tmux kill-server'"
echo "y abre los launchers de nuevo."
echo ""
printf "Presiona Enter para cerrar. "
read _
