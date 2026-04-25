@echo off
REM ============================================================
REM  CLAUDE CODE - Instalador Universal Windows
REM  Doble-click aqui. Si no eres admin, se re-lanzara como admin.
REM ============================================================

REM Auto-elevacion a Administrador
>nul 2>&1 net session
if %errorlevel% neq 0 (
    echo Solicitando permisos de administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

REM Cambiar al directorio del .bat (soporta rutas con espacios)
cd /d "%~dp0"

REM Ejecutar el instalador PowerShell sin bloqueos de ExecutionPolicy
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0scripts\install-main.ps1"

echo.
echo Presiona cualquier tecla para cerrar.
pause >nul
