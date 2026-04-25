@echo off
REM Configura nombre corto de esta maquina (ej: PC1, PC2, PC-LAB)
REM Se usa en los nombres de sesion: OPUS47-PC1-1, SONNET-PC1-1, etc.
where wt >nul 2>&1
if %errorlevel% equ 0 (
    start "" wt.exe new-tab --title "SET-NAME" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/set-machine-name.sh"
) else (
    start "SET-NAME" wsl.exe bash -lic "bash ~/Desktop/CLAUDE-LAUNCHERS/set-machine-name.sh"
)
