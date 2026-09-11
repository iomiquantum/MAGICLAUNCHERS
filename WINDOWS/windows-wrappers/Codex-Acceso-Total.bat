@echo off
REM Lanzador Windows - Codex acceso total
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "CODEX-FULL" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/CODEX/Codex-Acceso-Total.sh"
) else (
    start "CODEX-FULL" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/CODEX/Codex-Acceso-Total.sh"
)
