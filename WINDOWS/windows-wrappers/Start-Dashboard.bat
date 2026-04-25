@echo off
REM Lanzador Windows - Arranca el dashboard-ORQUESTADOR (Node 3200 + Python 8420)
REM Y abre el navegador en http://localhost:3200
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "DASHBOARD" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/dashboard/START-DASHBOARD.sh"
) else (
    start "DASHBOARD" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/dashboard/START-DASHBOARD.sh"
)
timeout /t 3 /nobreak >nul
start "" http://localhost:3200
