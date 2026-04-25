@echo off
REM Lanzador Windows - KILL-ALL (mata todas las sesiones tmux)
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "KILL-ALL" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/KILL-ALL.sh"
) else (
    start "KILL-ALL" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/KILL-ALL.sh"
)
