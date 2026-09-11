#!/bin/bash
# Lanzador acceso total Codex (Linux/WSL). Uso: $0 [carpeta-proyecto]
CAFFEINATE=""
command -v caffeinate >/dev/null 2>&1 && CAFFEINATE="caffeinate -s"
STATE_DIR="$HOME/.codex-launchers"
mkdir -p "$STATE_DIR"
COUNTER_FILE="$STATE_DIR/full-access-session-counter"
SESSION_NUMBER=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
echo "$SESSION_NUMBER" > "$COUNTER_FILE"
if ! command -v codex >/dev/null 2>&1; then
  echo "Codex CLI no está instalado o no está disponible en PATH."
  read -p "Presiona Enter para cerrar. "
  exit 1
fi
PROJECT_DIR="$1"
if [ -z "$PROJECT_DIR" ]; then
  printf "Carpeta del proyecto: "
  read -r PROJECT_DIR
fi
if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  echo "No se seleccionó ningún proyecto válido."
  exit 0
fi
MACHINE_NAME=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "PC")
MACHINE_NAME=$(echo "$MACHINE_NAME" | tr -c 'a-zA-Z0-9' '-')
SESSION_NAME="CODEX-FULL-${MACHINE_NAME}-${SESSION_NUMBER}"
echo "ACCESO TOTAL ACTIVADO"
echo "Proyecto: $PROJECT_DIR"
echo "Sesión: $SESSION_NAME"
echo ""
exec tmux new-session -s "$SESSION_NAME" -c "$PROJECT_DIR" \
  "$CAFFEINATE codex --dangerously-bypass-approvals-and-sandbox --no-alt-screen"
