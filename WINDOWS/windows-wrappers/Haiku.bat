@echo off
REM Lanzador Windows - Claude Haiku 4.5
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "HAIKU" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/ClaudeCode-Haiku.sh"
) else (
    start "HAIKU" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/ClaudeCode-Haiku.sh"
)
