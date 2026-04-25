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
if [ -f "$FILE" ]; then
    CURRENT=$(tr -d '[:space:]' < "$FILE")
    [ -z "$CURRENT" ] && CURRENT="(archivo vacio - se borrara)"
fi

AUTO=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "PC")
AUTO=$(echo "$AUTO" | tr -dc 'a-zA-Z0-9-' | cut -c1-15)

echo ""
echo "========================================"
echo "  Configurar nombre de maquina"
echo "========================================"
echo ""
echo "Nombre actual:       $CURRENT"
echo "Hostname automatico: $AUTO"
echo ""
echo "Escribe el nombre corto para esta maquina (ej: PC1, MAC, PC-LAB)"
echo "  - Solo letras, numeros, guiones (no al inicio/final)"
echo "  - Max 15 caracteres"
echo "  - Espacios y caracteres raros se eliminan automaticamente"
echo "  - Deja vacio y Enter para volver al hostname automatico"
echo ""
read -p "Nuevo nombre: " RAW

# Limpieza paso a paso:
# 1) Quitar espacios al inicio/final
NEW=$(echo "$RAW" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
# 2) Borrar caracteres no permitidos
NEW=$(echo "$NEW" | tr -dc 'a-zA-Z0-9-')
# 3) Cortar a 15 caracteres
NEW=$(echo "$NEW" | cut -c1-15)
# 4) Colapsar guiones dobles y quitar inicial/final
NEW=$(echo "$NEW" | sed 's/--*/-/g; s/^-//; s/-$//')

echo ""
if [ -z "$RAW" ]; then
    rm -f "$FILE"
    echo "Nombre custom borrado. Los launchers usaran el hostname: $AUTO"
elif [ -z "$NEW" ]; then
    echo "ERROR: Tu input '$RAW' no tiene caracteres validos."
    echo "Use solo letras, numeros y guiones. No se guardo nada."
    read -p "Presiona Enter para cerrar. " _
    exit 1
else
    if [ "$NEW" != "$RAW" ]; then
        echo "Nota: tu input '$RAW' se limpio a '$NEW'"
    fi
    echo "$NEW" > "$FILE"
    echo ""
    echo "VERIFICACION - contenido del archivo:"
    echo "  archivo: $FILE"
    echo "  bytes:   $(wc -c < "$FILE" | tr -d '[:space:]')"
    echo "  texto:   [$(cat "$FILE")]"
    echo ""
    echo "Nombre guardado: $NEW"
    echo "Los launchers ahora usaran: OPUS47-${NEW}-1, SONNET-${NEW}-1, etc."
fi

echo ""
echo "Las sesiones ya abiertas mantienen su nombre viejo."
echo "Para aplicar el cambio: doble-click en Kill-All y abre launchers de nuevo."
echo ""
read -p "Presiona Enter para cerrar. " _
