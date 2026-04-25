#!/bin/bash
# ============================================================
# MAC/INSTALAR.command - Instala los .command originales de Mac
# en ~/Desktop/CLAUDE LAUNCHERS/ (replica exacta del setup de Miguel)
# ============================================================
set -e

cd "$(dirname "$0")"
MAC_DIR="$(pwd)"
REPO_DIR="$(dirname "$MAC_DIR")"

# ---- Password gate ----
source "$REPO_DIR/GENERICOS/scripts/verify-password.sh"
if ! verify_password; then
    exit 1
fi

echo ""
echo "========================================"
echo "  MAC - Instalando setup original"
echo "========================================"
echo ""

# ---- Dependencias ----
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew no detectado. Instalando..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

command -v tmux >/dev/null 2>&1 || { echo "Instalando tmux..."; brew install tmux; }
command -v node >/dev/null 2>&1 || { echo "Instalando node..."; brew install node; }
command -v claude >/dev/null 2>&1 || { echo "Instalando claude..."; npm install -g @anthropic-ai/claude-code; }

# ---- Copiar .command al Escritorio (estructura original) ----
DEST="$HOME/Desktop/CLAUDE LAUNCHERS"
STATE="$HOME/.claude-launchers"

echo ""
echo "== Copiando launchers a: $DEST =="
mkdir -p "$DEST/LAUNCHERS" "$DEST/ORQUESTADOR" "$DEST/BROADCAST-DISPATCH" "$DEST/dashboard-ORQUESTADOR" "$STATE"

cp "$MAC_DIR/LAUNCHERS/"*.command "$DEST/LAUNCHERS/"
cp "$MAC_DIR/ORQUESTADOR/ORQUESTADOR.command" "$DEST/ORQUESTADOR/"
cp "$MAC_DIR/BROADCAST-DISPATCH/"*.command "$DEST/BROADCAST-DISPATCH/"
cp "$MAC_DIR/dashboard/"* "$DEST/dashboard-ORQUESTADOR/"

chmod +x "$DEST/LAUNCHERS/"*.command
chmod +x "$DEST/ORQUESTADOR/"*.command
chmod +x "$DEST/BROADCAST-DISPATCH/"*.command
chmod +x "$DEST/dashboard-ORQUESTADOR/"*.command 2>/dev/null || true

# ---- Prompt del orquestador ----
cat > "$STATE/orquestador-prompt.txt" << 'EOF'
Eres el ORQUESTADOR. Puedes delegar tareas a trabajadores usando claude --print con diferentes modelos.

Comandos disponibles para delegar:

- Tarea rápida/barata:
  claude --print --model claude-haiku-4-5-20251001 -p "tarea aquí"

- Tarea intermedia:
  claude --print --model claude-sonnet-4-6 -p "tarea aquí"

- Tarea compleja:
  claude --print --model claude-opus-4-6 -p "tarea aquí"

Puedes lanzar varios en paralelo usando & al final de cada comando.
Cuando el usuario te pida algo, decide si lo haces tú directamente o si delegas a uno o más trabajadores según la complejidad.
Para tareas grandes, divide el trabajo entre múltiples workers y combina los resultados.
EOF

echo ""
echo "========================================"
echo "  INSTALACION COMPLETA"
echo "========================================"
echo ""
echo "Tienes en: $DEST/"
echo "  LAUNCHERS/            (Opus, Opus47, Sonnet, Haiku, Kill-All)"
echo "  ORQUESTADOR/          (ORQUESTADOR.command)"
echo "  BROADCAST-DISPATCH/   (BROADCAST + DISPATCH)"
echo "  dashboard-ORQUESTADOR/ (Start/Stop + server)"
echo ""
echo "Doble-click en cualquiera desde Finder y arranca la sesion."
echo ""
