@echo off
REM Actualiza los launchers .sh con la ultima version desde el repo
REM (usa el git clone o ZIP descomprimido que tengas localmente)
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "UPDATE" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/update-launchers.sh"
) else (
    start "UPDATE" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/update-launchers.sh"
)
