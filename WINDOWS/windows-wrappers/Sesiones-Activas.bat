@echo off
REM Lista sesiones tmux vivas y permite reconectar
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "SESIONES" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/SESIONES-ACTIVAS.sh"
) else (
    start "SESIONES" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/SESIONES-ACTIVAS.sh"
)
