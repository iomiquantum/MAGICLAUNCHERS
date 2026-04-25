@echo off
REM Lanzador Windows - Claude Sonnet 4.6
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "SONNET" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/ClaudeCode-Sonnet.sh"
) else (
    start "SONNET" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/ClaudeCode-Sonnet.sh"
)
