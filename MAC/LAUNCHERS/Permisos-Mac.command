#!/bin/zsh
# ============================================================
# Permisos-Mac.command - Da ownership al usuario actual de las
# rutas comunes de dev tools (Homebrew, npm globals, etc.)
# Usar cuando npm/brew fallen con EACCES o "not writable"
# ============================================================

clear
echo ""
echo "========================================"
echo "  Arreglar permisos Mac"
echo "  Usuario actual: $(whoami)"
echo "========================================"
echo ""
echo "Este launcher te asigna como dueno de las rutas donde los"
echo "instaladores (brew, npm) escriben. Arregla errores tipo:"
echo "  - EACCES: permission denied"
echo "  - /opt/homebrew is not writable"
echo "  - The following directories are not writable by your user"
echo ""

# Rutas que existen en el sistema
SYSTEM_PATHS=(
    /opt/homebrew
    /usr/local/lib/node_modules
    /usr/local/bin
    /usr/local/share
    /usr/local/include
    /usr/local/Cellar
    /usr/local/Homebrew
    /usr/local/Caskroom
    /usr/local/var
)

# Rutas del usuario (no necesitan sudo)
USER_PATHS=(
    "$HOME/.npm"
    "$HOME/.cache/npm"
    "$HOME/.config"
    "$HOME/.claude"
    "$HOME/.claude-launchers"
)

echo "Rutas detectadas que se van a procesar:"
echo ""
for p in "${SYSTEM_PATHS[@]}" "${USER_PATHS[@]}"; do
    [ -e "$p" ] && echo "  [ok] $p"
done
echo ""

printf "Continuar? Se te pedira tu password de Mac (s/N): "
read OK
if [ "$OK" != "s" ] && [ "$OK" != "S" ]; then
    echo "Cancelado."
    printf "Presiona Enter para cerrar. "
    read _
    exit 0
fi

echo ""
echo "Aplicando ownership..."
echo ""

for p in "${SYSTEM_PATHS[@]}"; do
    if [ -e "$p" ]; then
        echo "  chown -R $(whoami) $p"
        sudo chown -R $(whoami) "$p" 2>/dev/null
    fi
done

for p in "${USER_PATHS[@]}"; do
    if [ -e "$p" ]; then
        echo "  chown -R $(whoami) $p"
        chown -R $(whoami) "$p" 2>/dev/null
    fi
done

echo ""
echo "========================================"
echo "  LISTO"
echo "========================================"
echo ""
echo "Ahora deberias poder:"
echo "  - Usar 'brew install' sin problemas"
echo "  - Usar 'npm install -g' sin sudo"
echo "  - Correr INSTALAR.command sin errores de permisos"
echo ""
printf "Presiona Enter para cerrar. "
read _
