@echo off
REM Lanzador Windows - BROADCAST (misma tarea a todas las sesiones)
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "BROADCAST" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/BROADCAST.sh"
) else (
    start "BROADCAST" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/BROADCAST.sh"
)
