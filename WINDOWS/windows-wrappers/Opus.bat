@echo off
REM Lanzador Windows - Claude Opus 4.6 (legacy)
REM Abre WSL y ejecuta el launcher bash dentro
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "OPUS" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/ClaudeCode-Opus.sh"
) else (
    start "OPUS" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/ClaudeCode-Opus.sh"
)
