#!/bin/bash
# ============================================================
# set-machine-name.sh - Configura el nombre corto de esta maquina
# Se guarda en ~/.claude-launchers/machine-name
# Los launchers lo leen y lo usan en los nombres de sesion.
# ============================================================

STATE="$HOME/.claude-launchers"
mkdir -p "$STATE"
FILE="$STATE/machine-name"

CURRENT="(ninguno - usa hostname automatico)"
[ -f "$FILE" ] && CURRENT=$(cat "$FILE" | tr -d '[:space:]')

AUTO=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "PC")
AUTO=$(echo "$AUTO" | tr -c 'a-zA-Z0-9' '-' | cut -c1-15)

echo ""
echo "========================================"
echo "  Configurar nombre de maquina"
echo "========================================"
echo ""
echo "Nombre actual:      $CURRENT"
echo "Hostname automatico: $AUTO"
echo ""
echo "Escribe el nombre corto para esta maquina (ej: PC1, MAC, PC-LAB)"
echo "  - Solo letras, numeros, guiones"
echo "  - Max 15 caracteres"
echo "  - Deja vacio y Enter para volver al hostname automatico"
echo ""
read -p "Nuevo nombre: " NEW

# Limpia: solo letras/numeros/guiones, max 15 chars, sin guiones al inicio/final, sin guiones dobles
NEW=$(echo "$NEW" | tr -c 'a-zA-Z0-9-' '' | cut -c1-15)
NEW=$(echo "$NEW" | sed 's/--*/-/g; s/^-//; s/-$//')

if [ -z "$NEW" ]; then
    rm -f "$FILE"
    echo ""
    echo "Nombre custom borrado. Los launchers usaran el hostname automatico: $AUTO"
else
    echo "$NEW" > "$FILE"
    echo ""
    echo "Nombre guardado: $NEW"
    echo "Los launchers ahora usaran: OPUS47-${NEW}-1, SONNET-${NEW}-1, etc."
fi
echo ""
echo "Los counters actuales se mantienen. Para reiniciarlos:"
echo "  rm $STATE/*-counter"
echo ""
read -p "Presiona Enter para cerrar. " _
