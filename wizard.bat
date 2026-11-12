@echo off
setlocal enabledelayedexpansion

set "PROJECT_ROOT=%~dp0"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"
set "PATH=%PROJECT_ROOT%\.node_env;%PATH%"

echo [INFO] Generando el instalador interactivo (Wizard NSIS) para Windows...

if not exist "%PROJECT_ROOT%\node_modules\.bin\electron-builder.cmd" (
    echo [FAIL] electron-builder no esta disponible. Ejecute setup.bat primero.
    exit /b 1
)

:: Asegurar que el backend este compilado antes de generar el instalador
if exist "%PROJECT_ROOT%\src\backend\tsconfig.json" (
    echo [INFO] Actualizando compilacion TypeScript del backend...
    call npx.cmd tsc -p "%PROJECT_ROOT%\src\backend\tsconfig.json"
)

call "%PROJECT_ROOT%\node_modules\.bin\electron-builder.cmd" --win nsis
if errorlevel 1 (
    echo [FAIL] Error al generar el instalador NSIS.
    exit /b 1
)

echo [INFO] ¡Wizard generado con exito! Revisa la carpeta 'dist\' para encontrar tu instalador .exe.
endlocal
