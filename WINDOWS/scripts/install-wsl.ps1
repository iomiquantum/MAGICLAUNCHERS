# ============================================================
# install-wsl.ps1 - Instala WSL2 + Ubuntu si no estan presentes
# ============================================================

Write-Host ""
Write-Host "== Verificando WSL2 + Ubuntu ==" -ForegroundColor Cyan
Write-Host ""

# ¿WSL instalado?
$wslInstalled = $false
try {
    $null = wsl.exe --status 2>&1
    if ($LASTEXITCODE -eq 0) { $wslInstalled = $true }
} catch {}

if (-not $wslInstalled) {
    Write-Host "WSL no detectado. Instalando (esto puede tardar varios minutos)..." -ForegroundColor Yellow
    Write-Host ""
    # Activa features + instala Ubuntu por defecto
    wsl.exe --install -d Ubuntu --no-launch
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: wsl --install fallo. Intenta manualmente:" -ForegroundColor Red
        Write-Host "  1. Abre PowerShell como Admin" -ForegroundColor Red
        Write-Host "  2. wsl --install" -ForegroundColor Red
        Write-Host "  3. Reinicia el PC" -ForegroundColor Red
        Write-Host "  4. Vuelve a correr INSTALAR.bat" -ForegroundColor Red
        return $false
    }
    Write-Host ""
    Write-Host "WSL instalado. DEBES REINICIAR EL PC ahora." -ForegroundColor Yellow
    Write-Host "Despues del reinicio:" -ForegroundColor Yellow
    Write-Host "  1. Se abrira Ubuntu automaticamente y te pedira crear usuario+password" -ForegroundColor Yellow
    Write-Host "  2. Cuando termines, vuelve a correr INSTALAR.bat para continuar" -ForegroundColor Yellow
    Write-Host ""
    $r = Read-Host "Reiniciar ahora? (s/N)"
    if ($r -eq "s" -or $r -eq "S") {
        Restart-Computer -Force
    }
    return $false
}

Write-Host "WSL ya instalado."

# Default a WSL2
wsl.exe --set-default-version 2 2>&1 | Out-Null

# ¿Ubuntu instalado?
$distros = wsl.exe --list --quiet 2>&1 | Out-String
if ($distros -notmatch "Ubuntu") {
    Write-Host "Ubuntu no detectado. Instalando..." -ForegroundColor Yellow
    wsl.exe --install -d Ubuntu --no-launch
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: No se pudo instalar Ubuntu. Intenta manualmente desde Microsoft Store." -ForegroundColor Red
        return $false
    }
    Write-Host ""
    Write-Host "Ubuntu instalado. Debes abrirlo UNA VEZ para crear usuario/password." -ForegroundColor Yellow
    Write-Host "Abriendo Ubuntu ahora..." -ForegroundColor Yellow
    Start-Process "ubuntu.exe"
    Write-Host ""
    Write-Host "Cuando termines de crear usuario en Ubuntu, vuelve aqui y presiona Enter." -ForegroundColor Yellow
    Read-Host "Presiona Enter cuando Ubuntu este listo"
}

Write-Host "Ubuntu listo." -ForegroundColor Green
Write-Host ""
return $true
