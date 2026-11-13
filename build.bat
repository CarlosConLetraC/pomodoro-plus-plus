@echo off
setlocal enabledelayedexpansion

set "PROJECT_ROOT=%~dp0"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"
set "PATH=%PROJECT_ROOT%\.node_env;%PATH%"

echo [INFO] Iniciando compilacion y empaquetado para Windows...

if not exist "%PROJECT_ROOT%\node_modules\.bin\electron-builder.cmd" (
    echo [FAIL] Error: electron-builder no esta instalado. Ejecuta setup.bat primero.
    exit /b 1
)

echo [INFO] Compilando fuentes de TypeScript del backend...
call npx.cmd tsc -p "%PROJECT_ROOT%\src\backend\tsconfig.json"
if errorlevel 1 (
    echo [FAIL] Error compilando TypeScript.
    exit /b 1
)

echo [INFO] Compilando estructura con electron-builder...
call "%PROJECT_ROOT%\node_modules\.bin\electron-builder.cmd" --win nsis
if errorlevel 1 (
    echo [FAIL] Error en electron-builder.
    exit /b 1
)

echo [INFO] Empaquetado completado con exito. Entregable listo en la carpeta 'dist\'
endlocal
