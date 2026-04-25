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
if [ -f "$FILE" ]; then
    CURRENT=$(tr -d '[:space:]' < "$FILE")
    [ -z "$CURRENT" ] && CURRENT="(archivo vacio - se borrara)"
fi

AUTO=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "MAC")
AUTO=$(echo "$AUTO" | tr -dc 'a-zA-Z0-9-' | cut -c1-15)

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
echo "  - Solo letras, numeros, guiones (no al inicio/final)"
echo "  - Espacios y caracteres raros se eliminan automaticamente"
echo "  - Enter vacio = borrar custom, usar hostname"
echo ""
printf "Nuevo nombre: "
read RAW

# Limpieza paso a paso:
# 1) Quitar espacios al inicio/final
NEW=$(echo "$RAW" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
# 2) Borrar caracteres no permitidos (solo dejar a-zA-Z0-9-)
NEW=$(echo "$NEW" | tr -dc 'a-zA-Z0-9-' )
# 3) Cortar a 15 caracteres
NEW=$(echo "$NEW" | cut -c1-15)
# 4) Colapsar guiones dobles, quitar guion inicial/final
NEW=$(echo "$NEW" | sed 's/--*/-/g; s/^-//; s/-$//')

echo ""
if [ -z "$RAW" ]; then
    rm -f "$FILE"
    echo "Nombre custom borrado."
    echo "Los launchers usaran el hostname: $AUTO"
elif [ -z "$NEW" ]; then
    echo "ERROR: Tu input '$RAW' no tiene caracteres validos."
    echo "Use solo letras, numeros y guiones. No se guardo nada."
    printf "Presiona Enter para cerrar. "
    read _
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
