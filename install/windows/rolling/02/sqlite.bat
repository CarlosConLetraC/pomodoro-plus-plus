@echo off
setlocal enabledelayedexpansion

set "PATH=%CD%\.node_env;%PATH%"
set "PROJECT_ROOT=%CD%"
set "BACKEND_NATIVE_DIR=src\backend\native"

if not defined SQLITE_VERSION set "SQLITE_VERSION=3.54.1"
if not defined SQLITE_TAR_VERSION set "SQLITE_TAR_VERSION=3540100"

set "SQLITE_URL=https://www.sqlite.org/2026/sqlite-autoconf-%SQLITE_TAR_VERSION%.tar.gz"

echo [INFO] Localizando cualquier version de Visual Studio instalada (vcvars64.bat)...
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" set "VSWHERE=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"

set "VS_PATH="
if exist "%VSWHERE%" (
    for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
        set "VS_PATH=%%i"
    )
)

if not defined VS_PATH (
    echo [FAIL] No se encontro ninguna instalacion de Visual Studio con herramientas C++ ^(MSVC^).
    exit /b 1
)

echo [INFO] Usando Visual Studio en: "%VS_PATH%"
if exist "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat" (
    call "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "%VS_PATH%\Common7\Tools\VsDevCmd.bat" (
    call "%VS_PATH%\Common7\Tools\VsDevCmd.bat" -arch=x64
) else (
    echo [FAIL] No se encontro el script de inicializacion de MSVC en esta version de Visual Studio.
    exit /b 1
)

echo [INFO] Preparando codigo fuente de SQLite v%SQLITE_VERSION%...
if not exist "%BACKEND_NATIVE_DIR%" mkdir "%BACKEND_NATIVE_DIR%"
if not exist "%BACKEND_NATIVE_DIR%\sqlite-src" mkdir "%BACKEND_NATIVE_DIR%\sqlite-src"

if not exist "%BACKEND_NATIVE_DIR%\sqlite-autoconf.tar.gz" (
    echo [INFO] Descargando desde: %SQLITE_URL%
    curl.exe -fsSL "%SQLITE_URL%" -o "%BACKEND_NATIVE_DIR%\sqlite-autoconf.tar.gz"
    if errorlevel 1 (
        echo [FAIL] Error al descargar el codigo fuente de SQLite.
        exit /b 1
    )
)

if not exist "%BACKEND_NATIVE_DIR%\sqlite-src\sqlite3.c" (
    tar.exe -xzf "%BACKEND_NATIVE_DIR%\sqlite-autoconf.tar.gz" --strip-components=1 -C "%BACKEND_NATIVE_DIR%\sqlite-src"
)

echo [INFO] Generando binding.gyp compatible con Windows/MSVC...
(
echo {
echo   "targets": [
echo     {
echo       "target_name": "sqlite_native",
echo       "sources": [
echo         "sqlite_addon.cpp",
echo         "sqlite-src/sqlite3.c"
echo       ],
echo       "include_dirs": [
echo         "sqlite-src",
echo         "../../../node_modules/node-addon-api"
echo       ],
echo       "defines": [
echo         "SQLITE_THREADSAFE=1",
echo         "SQLITE_ENABLE_FTS5=1",
echo         "NAPI_DISABLE_CPP_EXCEPTIONS"
echo       ]
echo     }
echo   ]
echo }
) > "%BACKEND_NATIVE_DIR%\binding.gyp"

if not exist "node_modules\node-addon-api" (
    echo [INFO] Instalando node-addon-api...
    call npm.cmd install node-addon-api
)

if exist "%BACKEND_NATIVE_DIR%\sqlite_addon.cpp" (
    echo [INFO] Compilando sqlite_native.node con node-gyp y MSVC...
    cd "%BACKEND_NATIVE_DIR%"
    call npx.cmd node-gyp clean
    call npx.cmd node-gyp configure
    call npx.cmd node-gyp build
    if errorlevel 1 (
        cd "%PROJECT_ROOT%"
        exit /b 1
    )
    cd "%PROJECT_ROOT%"
    echo [INFO] Modulo nativo sqlite_native.node compilado con exito en Windows.
) else (
    echo [WARN] Falta crear sqlite_addon.cpp en %BACKEND_NATIVE_DIR%.
)

endlocal
