# ============================================================
# check-system.ps1 - Verifica compatibilidad del PC
# Devuelve $true si el sistema sirve, $false si no.
# ============================================================

Write-Host ""
Write-Host "== Verificando sistema ==" -ForegroundColor Cyan
Write-Host ""

$ok = $true

# --- Version Windows ---
$os = Get-CimInstance Win32_OperatingSystem
$winVer = [int]($os.Caption -replace '[^0-9]','' | Select-Object -First 1)
Write-Host ("SO:        {0}" -f $os.Caption)
Write-Host ("Build:     {0}" -f $os.BuildNumber)

if ($os.Caption -notmatch "Windows (10|11)") {
    Write-Host "ERROR: Se requiere Windows 10 o 11." -ForegroundColor Red
    $ok = $false
}
# WSL2 requiere build >= 19041 en Win10
if ($os.BuildNumber -lt 19041) {
    Write-Host "ERROR: Build muy antiguo. WSL2 necesita build 19041+." -ForegroundColor Red
    $ok = $false
}

# --- Arquitectura 64-bit ---
if ([Environment]::Is64BitOperatingSystem -eq $false) {
    Write-Host "ERROR: Se requiere Windows 64-bit." -ForegroundColor Red
    $ok = $false
} else {
    Write-Host "Arquitectura: 64-bit OK"
}

# --- RAM ---
$ramGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
Write-Host ("RAM total: {0} GB" -f $ramGB)
if ($ramGB -lt 4) {
    Write-Host "ERROR: RAM menor a 4GB, WSL+Claude no funcionara bien." -ForegroundColor Red
    $ok = $false
} elseif ($ramGB -lt 8) {
    Write-Host "AVISO: RAM menor a 8GB. Funcionara pero limita sesiones paralelas." -ForegroundColor Yellow
}

# --- Disco libre en C: ---
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeGB = [math]::Round($disk.FreeSpace / 1GB, 1)
Write-Host ("Disco C:   {0} GB libres" -f $freeGB)
if ($freeGB -lt 10) {
    Write-Host "ERROR: Menos de 10GB libres. WSL+Ubuntu requiere al menos 10GB." -ForegroundColor Red
    $ok = $false
} elseif ($freeGB -lt 20) {
    Write-Host "AVISO: Menos de 20GB libres. Considera limpiar antes de seguir." -ForegroundColor Yellow
    Write-Host "       Abre 'Storage Sense' en Configuracion para liberar espacio." -ForegroundColor Yellow
}

# --- Admin check ---
$admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $admin) {
    Write-Host "ERROR: Este script debe correr como Administrador." -ForegroundColor Red
    $ok = $false
} else {
    Write-Host "Admin:     OK"
}

Write-Host ""
if ($ok) {
    Write-Host "Sistema compatible. Continuando..." -ForegroundColor Green
} else {
    Write-Host "Sistema NO compatible. Revisa los errores arriba." -ForegroundColor Red
}
Write-Host ""

return $ok
