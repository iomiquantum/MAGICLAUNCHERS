# ============================================================
# verify-password.ps1 - Password gate PBKDF2-HMAC-SHA256
#   200000 iteraciones. Usa .NET Rfc2898DeriveBytes (builtin).
# Devuelve $true si pasa, $false si falla 3 veces.
# ============================================================

function Invoke-VerifyPassword {
    # Buscar .auth-hash subiendo directorios
    $dir = $PSScriptRoot
    $hashFile = $null
    while ($dir -and (Test-Path $dir)) {
        $candidate = Join-Path $dir ".auth-hash"
        if (Test-Path $candidate) {
            $hashFile = $candidate
            break
        }
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { break }
        $dir = $parent
    }

    if (-not $hashFile) {
        Write-Host "ERROR: No encuentro .auth-hash" -ForegroundColor Red
        return $false
    }

    $expected = (Get-Content $hashFile -Raw).Trim()
    $salt = [Text.Encoding]::UTF8.GetBytes("MAGICLAUNCHERS-v1-iomi")

    for ($t = 1; $t -le 3; $t++) {
        Write-Host ""
        $sec = Read-Host "Clave de acceso MAGICLAUNCHERS" -AsSecureString
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) | Out-Null

        $kdf = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($plain, $salt, 200000, "SHA256")
        $bytes = $kdf.GetBytes(32)
        $actual = ([BitConverter]::ToString($bytes) -replace '-','').ToLower()
        $kdf.Dispose()

        if ($actual -eq $expected) {
            Write-Host "Acceso concedido." -ForegroundColor Green
            return $true
        } else {
            Write-Host ("Clave incorrecta. Intentos: {0}/3" -f $t) -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "Demasiados intentos fallidos. Abortando." -ForegroundColor Red
    return $false
}
