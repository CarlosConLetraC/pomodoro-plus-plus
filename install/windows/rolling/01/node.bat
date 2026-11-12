@echo off
setlocal

set "LOCAL_NODE_DIR=%CD%\.node_env"
set "NODE_URL=https://nodejs.org/dist/v%NODE_VERSION%/node-v%NODE_VERSION%-win-%ARCH%.zip"
set "TEMP_ZIP=%TEMP%\node-win.zip"
set "TEMP_EXTRACT=%TEMP%\node-extract"

if exist "%LOCAL_NODE_DIR%\node.exe" (
    echo [INFO] Node.js ya esta instalado localmente en .node_env
    exit /b 0
)

echo [INFO] Descargando Node.js v%NODE_VERSION% (%ARCH%) desde %NODE_URL%...
curl.exe -fsSL "%NODE_URL%" -o "%TEMP_ZIP%"
if errorlevel 1 exit /b 1

echo [INFO] Extrayendo Node.js en %LOCAL_NODE_DIR%...
if exist "%TEMP_EXTRACT%" rmdir /s /q "%TEMP_EXTRACT%"
mkdir "%TEMP_EXTRACT%"
tar.exe -xf "%TEMP_ZIP%" -C "%TEMP_EXTRACT%"

mkdir "%LOCAL_NODE_DIR%"
xcopy /E /I /Y "%TEMP_EXTRACT%\node-v%NODE_VERSION%-win-%ARCH%\*" "%LOCAL_NODE_DIR%\" >nul

:: Limpieza de temporales
del /f /q "%TEMP_ZIP%"
rmdir /s /q "%TEMP_EXTRACT%"

set "PATH=%LOCAL_NODE_DIR%;%PATH%"
node -v
npm -v

echo [INFO] Entorno Node local listo.
endlocal
