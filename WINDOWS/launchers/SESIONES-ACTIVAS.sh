#!/bin/bash
# Mismo script que GENERICOS, se copia aqui para que el instalador Windows lo copie a WSL
clear
echo ""
echo "========================================"
echo "  Sesiones Claude activas"
echo "========================================"
echo ""

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

echo "Sesiones vivas:"
echo ""
i=1
declare -a LIST
while IFS= read -r s; do
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

printf '\033]0;%s\007\033]2;%s\007' "$SEL" "$SEL"
exec tmux attach -t "$SEL"
