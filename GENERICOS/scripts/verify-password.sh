#!/bin/bash
# ============================================================
# verify-password.sh - Password gate PBKDF2-HMAC-SHA256
#   200000 iteraciones, salt fijo
# Uso: source verify-password.sh && verify_password
# ============================================================

verify_password() {
    local HASH_FILE
    # Buscar .auth-hash subiendo directorios
    local DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    while [ "$DIR" != "/" ]; do
        if [ -f "$DIR/.auth-hash" ]; then
            HASH_FILE="$DIR/.auth-hash"
            break
        fi
        DIR="$(dirname "$DIR")"
    done

    if [ -z "$HASH_FILE" ]; then
        echo "ERROR: No encuentro .auth-hash"
        return 1
    fi

    local EXPECTED
    EXPECTED=$(tr -d '[:space:]' < "$HASH_FILE")

    if ! command -v python3 >/dev/null 2>&1; then
        echo "ERROR: python3 requerido para verificar clave."
        echo "  macOS: deberia venir preinstalado"
        echo "  Ubuntu/Debian: sudo apt install python3"
        return 1
    fi

    local TRIES=0
    while [ $TRIES -lt 3 ]; do
        TRIES=$((TRIES+1))
        echo ""
        read -s -p "Clave de acceso MAGICLAUNCHERS: " PASS
        echo ""

        local ACTUAL
        ACTUAL=$(python3 -c "import hashlib,sys; print(hashlib.pbkdf2_hmac('sha256', sys.argv[1].encode(), b'MAGICLAUNCHERS-v1-iomi', 200000).hex())" "$PASS")

        if [ "$ACTUAL" = "$EXPECTED" ]; then
            echo "Acceso concedido."
            return 0
        else
            echo "Clave incorrecta. Intentos: $TRIES/3"
        fi
    done

    echo ""
    echo "Demasiados intentos fallidos. Abortando."
    return 1
}
