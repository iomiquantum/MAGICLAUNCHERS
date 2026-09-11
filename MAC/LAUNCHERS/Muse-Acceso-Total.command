#!/bin/zsh

# ATENCIÓN: este lanzador da a Muse acceso completo al usuario actual,
# sin sandbox y sin solicitudes de aprobación (--yolo).
STATE_DIR="$HOME/.muse-launchers"
mkdir -p "$STATE_DIR"

COUNTER_FILE="$STATE_DIR/full-access-session-counter"
SESSION_NUMBER=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
echo "$SESSION_NUMBER" > "$COUNTER_FILE"

if ! command -v muse >/dev/null 2>&1; then
  echo "Muse CLI no está instalado o no está disponible en PATH."
  echo "Presiona Enter para cerrar."
  read
  exit 1
fi

PROJECT_DIR=$(osascript -e 'POSIX path of (choose folder with prompt "Elige el proyecto para abrir con Muse (acceso total)")' 2>/dev/null)

if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  echo "No se seleccionó ningún proyecto."
  echo "Presiona Enter para cerrar."
  read
  exit 0
fi

MACHINE_NAME=$(hostname -s 2>/dev/null || echo "MAC")
MACHINE_NAME=$(echo "$MACHINE_NAME" | tr -c 'a-zA-Z0-9' '-')
SESSION_NAME="MUSE-FULL-${MACHINE_NAME}-${SESSION_NUMBER}"

echo "ACCESO TOTAL ACTIVADO"
echo "Proyecto: $PROJECT_DIR"
echo "Sesión: $SESSION_NAME"
echo ""

exec tmux new-session -s "$SESSION_NAME" -c "$PROJECT_DIR" \
  "caffeinate -s muse --yolo"
