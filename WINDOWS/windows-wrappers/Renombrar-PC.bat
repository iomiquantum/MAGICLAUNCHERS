@echo off
REM ============================================================
REM  Renombrar-PC.bat - Asigna un nombre corto a esta PC
REM  Ejecuta el script del repo (siempre actualizado)
REM  Guarda en ~/.claude-launchers/machine-name dentro de WSL
REM ============================================================
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "RENOMBRAR" wsl.exe bash -lic "bash <(curl -fsSL https://raw.githubusercontent.com/iomiquantum/MAGICLAUNCHERS/main/GENERICOS/scripts/set-machine-name.sh)"
) else (
    start "RENOMBRAR" wsl.exe bash -lic "bash <(curl -fsSL https://raw.githubusercontent.com/iomiquantum/MAGICLAUNCHERS/main/GENERICOS/scripts/set-machine-name.sh)"
)
