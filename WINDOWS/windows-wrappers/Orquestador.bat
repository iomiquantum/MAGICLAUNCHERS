@echo off
REM Lanzador Windows - ORQUESTADOR (tu MAESTRO)
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "ORQUESTADOR" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/ORQUESTADOR.sh"
) else (
    start "ORQUESTADOR" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/ORQUESTADOR.sh"
)
