@echo off
setlocal enabledelayedexpansion

:: Obtener la ruta absoluta del directorio del proyecto (equivalente a PROJECT_ROOT)
set "PROJECT_ROOT=%~dp0"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

:: Inyectar el entorno local de Node.js (.node_env) en el PATH de forma prioritaria
set "PATH=%PROJECT_ROOT%\.node_env;%PATH%"

echo [INFO] Entorno local cargado (.node_env)
echo [INFO] Verificando versiones locales...
call node -v
call npm -v
echo [INFO] Codigo de salida: %errorlevel%

:: Verificar que Electron exista localmente (.cmd en Windows)
if not exist "%PROJECT_ROOT%\node_modules\.bin\electron.cmd" (
    echo [FAIL] Electron no esta instalado en node_modules\.bin\. Ejecute setup.bat primero.
    exit /b 1
)

:: Compilar TypeScript en el backend antes de arrancar
echo [INFO] Compilando fuentes de TypeScript del backend...
call npx.cmd tsc -p "%PROJECT_ROOT%\src\backend\tsconfig.json"
if errorlevel 1 (
    echo [FAIL] Error compilando TypeScript.
    exit /b 1
)

echo [INFO] Lanzando la aplicacion Electron...
call "%PROJECT_ROOT%\node_modules\.bin\electron.cmd" "%PROJECT_ROOT%" %*
endlocal
