@echo off
REM Lanzador Windows - Claude Opus 4.7
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "OPUS47" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/ClaudeCode-Opus47.sh"
) else (
    start "OPUS47" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/ClaudeCode-Opus47.sh"
)
