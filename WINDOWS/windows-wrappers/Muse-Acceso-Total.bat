@echo off
REM Lanzador Windows - Muse acceso total
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "MUSE-FULL" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/Muse-Acceso-Total.sh"
) else (
    start "MUSE-FULL" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/Muse-Acceso-Total.sh"
)
