#!/bin/bash
# ============================================================
# setup-ubuntu.sh - Instala dentro de WSL/Ubuntu:
#   apt update, curl, git, tmux, Node.js LTS, Python3,
#   @anthropic-ai/claude-code
# Idempotente: solo instala lo que falta.
# ============================================================
set -e

echo ""
echo "== Actualizando lista de paquetes apt =="
sudo apt-get update -y

echo ""
echo "== Instalando utilidades base (curl git tmux ca-certificates build-essential) =="
sudo apt-get install -y curl git tmux ca-certificates build-essential python3 python3-pip

echo ""
echo "== Verificando Node.js =="
if ! command -v node >/dev/null 2>&1; then
    echo "Node no encontrado. Instalando Node.js LTS..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "Node ya instalado: $(node --version)"
fi

echo ""
echo "== Verificando Claude Code CLI =="
if ! command -v claude >/dev/null 2>&1; then
    echo "Instalando @anthropic-ai/claude-code globalmente..."
    sudo npm install -g @anthropic-ai/claude-code
else
    echo "Claude ya instalado: $(claude --version 2>/dev/null || echo 'version desconocida')"
fi

echo ""
echo "== Versiones finales =="
echo "  node:   $(node --version)"
echo "  npm:    $(npm --version)"
echo "  tmux:   $(tmux -V)"
echo "  python: $(python3 --version)"
echo "  claude: $(claude --version 2>/dev/null || echo '(correr claude una vez para auth)')"
echo ""
echo "Ubuntu listo."
