#!/bin/bash
# ============================================================
# install-universal.sh - Instalador cross-OS (macOS + Linux)
# Detecta el SO y hace lo correcto:
#   - macOS: brew para tmux, npm para claude
#   - Linux (apt/dnf/pacman): instala tmux, node, claude
# Copia los launchers a ~/Desktop/CLAUDE-LAUNCHERS/
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERICOS_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$(dirname "$GENERICOS_DIR")"

# --- Password gate ---
source "$SCRIPT_DIR/verify-password.sh"
if ! verify_password; then
    exit 1
fi

echo ""
echo "========================================"
echo "  MAGICLAUNCHERS - Instalador Universal"
echo "========================================"
echo ""

# --- Detectar SO ---
OS_TYPE=""
case "$(uname -s)" in
    Darwin*) OS_TYPE="mac" ;;
    Linux*)  OS_TYPE="linux" ;;
    *)       echo "SO no soportado: $(uname -s)"; exit 1 ;;
esac
echo "SO detectado: $OS_TYPE"
echo ""

# --- macOS ---
install_mac() {
    echo "== Instalando en macOS =="

    # Homebrew
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew no detectado. Instalando..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Añade brew al PATH para esta sesion (Apple Silicon)
        [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    # tmux
    if ! command -v tmux >/dev/null 2>&1; then
        echo "Instalando tmux..."
        brew install tmux
    fi

    # Node
    if ! command -v node >/dev/null 2>&1; then
        echo "Instalando Node.js LTS..."
        brew install node
    fi

    # claude
    if ! command -v claude >/dev/null 2>&1; then
        echo "Instalando @anthropic-ai/claude-code..."
        npm install -g @anthropic-ai/claude-code
    fi
}

# --- Linux (detecta gestor de paquetes) ---
install_linux() {
    echo "== Instalando en Linux =="

    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y
        sudo apt-get install -y curl git tmux ca-certificates build-essential python3
        if ! command -v node >/dev/null 2>&1; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y curl git tmux python3 nodejs npm
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm curl git tmux python nodejs npm
    else
        echo "ERROR: No encuentro apt, dnf ni pacman."
        echo "Instala manualmente: tmux, node, npm, python3"
        exit 1
    fi

    if ! command -v claude >/dev/null 2>&1; then
        sudo npm install -g @anthropic-ai/claude-code
    fi
}

# --- Ejecutar segun SO ---
case "$OS_TYPE" in
    mac)   install_mac ;;
    linux) install_linux ;;
esac

# --- Copiar launchers ---
echo ""
echo "== Instalando launchers =="
DEST="$HOME/Desktop/CLAUDE-LAUNCHERS"
STATE="$HOME/.claude-launchers"
mkdir -p "$DEST" "$STATE"

cp "$GENERICOS_DIR/launchers/"*.sh "$DEST/"
chmod +x "$DEST/"*.sh
cp "$GENERICOS_DIR/config/orquestador-prompt.txt" "$STATE/"

# En Mac, crear tambien .command symlinks (para doble-click desde Finder)
if [ "$OS_TYPE" = "mac" ]; then
    for f in "$DEST/"*.sh; do
        base=$(basename "$f" .sh)
        cp "$f" "$DEST/${base}.command"
        chmod +x "$DEST/${base}.command"
    done
fi

echo ""
echo "Launchers instalados en: $DEST"
ls -1 "$DEST/"

echo ""
echo "========================================"
echo "  INSTALACION COMPLETA"
echo "========================================"
echo ""
echo "PRIMER USO:"
echo "  1. Doble-click en cualquier launcher (ej: Haiku)"
echo "  2. Claude te pedira autenticar (solo la primera vez)"
echo ""
