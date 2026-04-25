@echo off
REM ============================================================
REM  Actualizar.bat - Descarga la ultima version del repo
REM  MAGICLAUNCHERS y actualiza los launchers en WSL
REM  Siempre usa la version mas reciente del script de update
REM ============================================================
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "ACTUALIZAR" wsl.exe bash -lic "bash <(curl -fsSL https://raw.githubusercontent.com/iomiquantum/MAGICLAUNCHERS/main/GENERICOS/scripts/update-launchers.sh)"
) else (
    start "ACTUALIZAR" wsl.exe bash -lic "bash <(curl -fsSL https://raw.githubusercontent.com/iomiquantum/MAGICLAUNCHERS/main/GENERICOS/scripts/update-launchers.sh)"
)
