@echo off
REM Lanzador Windows - DISPATCH (tarea a una sesion especifica)
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "DISPATCH" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/DISPATCH.sh"
) else (
    start "DISPATCH" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/DISPATCH.sh"
)
