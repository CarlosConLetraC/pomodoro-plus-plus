@echo off
setlocal

set "PATH=%CD%\.node_env;%PATH%"

echo [INFO] Instalando dependencias de Electron v%ELECTRON_VERSION% y electron-builder...
call npm.cmd install --save-dev "electron@%ELECTRON_VERSION%" electron-builder
if errorlevel 1 exit /b 1

echo [INFO] Verificando estructura de directorios src/...
if not exist "src\backend\index.js" (
    echo [FAIL] No se encontro src\backend\index.js
    exit /b 1
)
if not exist "src\frontend\index.html" (
    echo [FAIL] No se encontro src\frontend\index.html
    exit /b 1
)

echo [INFO] Verificando y generando package.json si no existe...
if not exist "package.json" (
    (
    echo {
    echo   "name": "pomodoro-plus-plus",
    echo   "version": "0.0.2",
    echo   "description": "Una aplicación de Pomodoro avanzada construida con Electron",
    echo   "main": "src/backend/index.js",
    echo   "scripts": {
    echo     "start": "electron ."
    echo   },
    echo   "author": "UniversalWare",
    echo   "license": "MIT"
    echo }
    ) > package.json
    echo [INFO] package.json generado exitosamente.
) else (
    echo [INFO] package.json ya existe.
)

echo [INFO] Aprovisionamiento de Electron completado.
echo [INFO] Instalando TypeScript en el entorno local...
call npm install -g typescript
call npm install --save-dev typescript
endlocal
