#!/bin/bash
# ============================================================
# SESIONES-ACTIVAS.sh - Lista sesiones tmux vivas y permite
# reconectarse a cualquiera eligiendo por numero.
# ============================================================

clear
echo ""
echo "========================================"
echo "  Sesiones Claude activas"
echo "========================================"
echo ""

# Recoger sesiones
SESSIONS=$(tmux ls -F '#{session_name}' 2>/dev/null)
if [ -z "$SESSIONS" ]; then
    echo "(ninguna sesion activa)"
    echo ""
    echo "Abre un launcher (Opus47, Haiku, etc.) para crear una."
    echo ""
    printf "Presiona Enter para cerrar. "
    read _
    exit 0
fi

# Detalles bonitos: nombre + cuanto tiempo lleva
echo "Sesiones vivas:"
echo ""
i=1
declare -a LIST
while IFS= read -r s; do
    # tiempo desde creacion
    AGE=$(tmux display-message -t "$s" -p '#{t/r:session_created}' 2>/dev/null)
    printf "  %d) %-30s  (%s)\n" "$i" "$s" "$AGE"
    LIST[$i]="$s"
    i=$((i+1))
done <<< "$SESSIONS"

echo ""
echo "  0) Salir sin reconectar"
echo ""
printf "Numero de la sesion a reconectar: "
read N

if [ "$N" = "0" ] || [ -z "$N" ]; then
    exit 0
fi

SEL="${LIST[$N]}"
if [ -z "$SEL" ]; then
    echo ""
    echo "Numero invalido."
    sleep 1
    exit 1
fi

# Setear titulo de la terminal con el nombre elegido
printf '\033]0;%s\007\033]2;%s\007' "$SEL" "$SEL"

exec tmux attach -t "$SEL"
