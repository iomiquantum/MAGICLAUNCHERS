# ============================================================
# create-shortcuts.ps1 - Copia los .bat al Escritorio Windows
# ============================================================

param(
    [string]$SetupRoot = "$PSScriptRoot\.."
)

Write-Host ""
Write-Host "== Creando accesos en el Escritorio de Windows ==" -ForegroundColor Cyan
Write-Host ""

$SrcDir  = Join-Path $SetupRoot "windows-wrappers"
$DestDir = Join-Path $env:USERPROFILE "Desktop\CLAUDE LAUNCHERS"

if (-not (Test-Path $SrcDir)) {
    Write-Host "ERROR: No encuentro '$SrcDir'" -ForegroundColor Red
    return $false
}

if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
}

Get-ChildItem -Path $SrcDir -Filter *.bat | ForEach-Object {
    $target = Join-Path $DestDir $_.Name
    Copy-Item -Path $_.FullName -Destination $target -Force
    Write-Host ("  OK  {0}" -f $_.Name) -ForegroundColor Green
}

Write-Host ""
Write-Host ("Todos los .bat copiados a: {0}" -f $DestDir) -ForegroundColor Green
Write-Host ""
return $true
