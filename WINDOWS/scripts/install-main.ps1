# ============================================================
# install-main.ps1 - Orquestador principal del instalador
# Ejecuta todos los pasos en orden y reporta al usuario.
# ============================================================

$ErrorActionPreference = "Continue"
$SetupRoot = Split-Path $PSScriptRoot -Parent

Clear-Host
Write-Host ""
Write-Host "  =====================================================" -ForegroundColor Cyan
Write-Host "   MAGICLAUNCHERS - Instalador Windows" -ForegroundColor Cyan
Write-Host "  =====================================================" -ForegroundColor Cyan
Write-Host ""

# ---- Password gate ----
. "$PSScriptRoot\verify-password.ps1"
if (-not (Invoke-VerifyPassword)) {
    pause
    exit 1
}
Write-Host ""

Write-Host "Este instalador hara:" -ForegroundColor White
Write-Host "  1. Verificar tu PC (RAM, disco, Windows version)"
Write-Host "  2. Configurar energia (no dormir con corriente)"
Write-Host "  3. Instalar WSL2 + Ubuntu (si faltan)"
Write-Host "  4. Dentro de Ubuntu: instalar Node.js, tmux, Claude Code"
Write-Host "  5. Copiar los 8 launchers .sh a Ubuntu"
Write-Host "  6. Copiar dashboard-ORQUESTADOR (Node + Python)"
Write-Host "  7. Crear accesos .bat en tu Escritorio de Windows"
Write-Host ""
Write-Host "Puedes correr este instalador varias veces - solo instalara lo que falte." -ForegroundColor Gray
Write-Host ""
$go = Read-Host "Continuar? (S/n)"
if ($go -eq "n" -or $go -eq "N") {
    Write-Host "Cancelado." -ForegroundColor Yellow
    exit 0
}

# ---- Paso 1: Check sistema ----
$sysOk = & "$PSScriptRoot\check-system.ps1"
if (-not $sysOk) {
    Write-Host "Instalacion abortada por incompatibilidad." -ForegroundColor Red
    pause
    exit 1
}

# ---- Paso 2: Energia ----
& "$PSScriptRoot\setup-power.ps1"

# ---- Paso 3: WSL + Ubuntu ----
$wslOk = & "$PSScriptRoot\install-wsl.ps1"
if (-not $wslOk) {
    Write-Host "WSL/Ubuntu requiere reinicio o intervencion manual. Vuelve a correr el instalador cuando termines." -ForegroundColor Yellow
    pause
    exit 0
}

# ---- Paso 4-6: dentro de Ubuntu ----
Write-Host ""
Write-Host "== Ejecutando instalacion dentro de Ubuntu ==" -ForegroundColor Cyan
Write-Host ""

# Convertir ruta Windows a ruta WSL (/mnt/c/...)
$SetupRootWsl = ($SetupRoot -replace '\\','/') -replace '^([A-Za-z]):','/mnt/$1'
$SetupRootWsl = $SetupRootWsl -replace '/mnt/([A-Za-z])','/mnt/$($matches[1].ToLower())'
# Simplificacion robusta:
$drive = $SetupRoot.Substring(0,1).ToLower()
$rest  = $SetupRoot.Substring(2) -replace '\\','/'
$SetupRootWsl = "/mnt/$drive$rest"

Write-Host "Ruta Windows: $SetupRoot"
Write-Host "Ruta en WSL:  $SetupRootWsl"
Write-Host ""

# Dar permisos de ejecucion a los .sh y correr setup
wsl.exe bash -c "chmod +x '$SetupRootWsl/scripts/'*.sh '$SetupRootWsl/launchers/'*.sh '$SetupRootWsl/dashboard/'*.sh 2>/dev/null; bash '$SetupRootWsl/scripts/setup-ubuntu.sh' && bash '$SetupRootWsl/scripts/install-launchers.sh' '$SetupRootWsl' && bash '$SetupRootWsl/scripts/install-dashboard.sh' '$SetupRootWsl'"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR durante la instalacion en Ubuntu. Revisa mensajes arriba." -ForegroundColor Red
    pause
    exit 1
}

# ---- Paso 7: Shortcuts Windows ----
& "$PSScriptRoot\create-shortcuts.ps1" -SetupRoot $SetupRoot | Out-Null

# ---- Final ----
Write-Host ""
Write-Host "  =====================================================" -ForegroundColor Green
Write-Host "   INSTALACION COMPLETA" -ForegroundColor Green
Write-Host "  =====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Lo que tienes ahora en tu Escritorio de Windows:" -ForegroundColor White
Write-Host "  Carpeta 'CLAUDE LAUNCHERS' con 10 .bat:"
Write-Host "    - Opus.bat          (Claude Opus 4.6)"
Write-Host "    - Opus47.bat        (Claude Opus 4.7)"
Write-Host "    - Sonnet.bat        (Claude Sonnet 4.6)"
Write-Host "    - Haiku.bat         (Claude Haiku 4.5)"
Write-Host "    - Orquestador.bat   (MAESTRO, opus 4.6 + prompt)"
Write-Host "    - Broadcast.bat     (tarea a TODAS las sesiones)"
Write-Host "    - Dispatch.bat      (tarea a UNA sesion)"
Write-Host "    - Kill-All.bat      (cierra todas las sesiones)"
Write-Host "    - Start-Dashboard.bat  (abre web dashboard)"
Write-Host "    - Stop-Dashboard.bat"
Write-Host ""
Write-Host "PRIMERA VEZ QUE USES CLAUDE:" -ForegroundColor Yellow
Write-Host "  1. Doble-click en cualquier launcher (ej: Haiku.bat)"
Write-Host "  2. Claude te pedira autenticar - sigue las instrucciones"
Write-Host "  3. Una vez autenticado, los demas launchers ya funcionan"
Write-Host ""
Write-Host "Listo. Puedes cerrar esta ventana." -ForegroundColor Green
pause
