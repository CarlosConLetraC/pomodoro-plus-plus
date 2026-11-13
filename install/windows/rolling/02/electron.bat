@echo off
setlocal

set "PATH=%CD%\.node_env;%PATH%"

echo [INFO] Verificando estructura de directorios src/...
if not exist "src\backend\index.js" (
    echo [FAIL] No se encontro src\backend\index.js
    exit /b 1
)
if not exist "src\frontend\index.html" (
    echo [FAIL] No se encontro src\frontend\index.html
    exit /b 1
)

echo [INFO] Generando y sobrescribiendo package.json con todas las dependencias...
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
echo   "license": "MIT",
echo   "devDependencies": {
echo     "electron": "%ELECTRON_VERSION%",
echo     "electron-builder": "^26.18.0",
echo     "typescript": "^5.0.0"
echo   }
echo }
) > package.json
echo [INFO] package.json actualizado exitosamente.

echo [INFO] Instalando todas las dependencias del proyecto...
call npm.cmd install
if errorlevel 1 exit /b 1

echo [INFO] Instalando TypeScript en el entorno global de forma auxiliar...
call npm install -g typescript

echo [INFO] Aprovisionamiento de Electron y dependencias completado.
endlocal