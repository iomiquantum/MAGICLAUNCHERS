@echo off
REM ============================================================
REM  Entrypoint Windows para GENERICOS
REM  Delega al instalador completo en ..\WINDOWS\INSTALAR.bat
REM  (WSL2 + Ubuntu + launchers)
REM ============================================================

cd /d "%~dp0"

if exist "..\WINDOWS\INSTALAR.bat" (
    echo.
    echo En Windows, el instalador completo esta en ..\WINDOWS\
    echo Ejecutando ese instalador...
    echo.
    call "..\WINDOWS\INSTALAR.bat"
) else (
    echo.
    echo ERROR: No encuentro ..\WINDOWS\INSTALAR.bat
    echo.
    echo Estas ejecutando esto dentro de la carpeta GENERICOS suelta?
    echo Descarga el repositorio MAGICLAUNCHERS completo.
    echo.
    pause
    exit /b 1
)
