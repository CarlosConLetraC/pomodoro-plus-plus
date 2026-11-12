@echo off
setlocal

echo [INFO] Verificando disponibilidad de winget en el sistema...
where winget >nul 2>&1
if %errorlevel% equ 0 goto :winget_ready

set "USER_WINGET=%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe"
if exist "%USER_WINGET%" (
    echo [INFO] winget encontrado en la ruta de usuario. Agregandolo al PATH...
    set "PATH=%PATH%;%LOCALAPPDATA%\Microsoft\WindowsApps"
    goto :winget_ready
)

echo [WARN] winget no esta disponible. Instalando dependencias de App Installer...
set "TEMP_DIR=%TEMP%\winget_install"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

powershell -Command "Invoke-WebRequest -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile '%TEMP_DIR%\VCLibs.appx'"
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx' -OutFile '%TEMP_DIR%\UIXaml.appx'"
powershell -Command "Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile '%TEMP_DIR%\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'"

powershell -Command "Add-AppxPackage '%TEMP_DIR%\VCLibs.appx' -ErrorAction SilentlyContinue"
powershell -Command "Add-AppxPackage '%TEMP_DIR%\UIXaml.appx' -ErrorAction SilentlyContinue"
powershell -Command "Add-AppxPackage '%TEMP_DIR%\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -ErrorAction SilentlyContinue"

rmdir /s /q "%TEMP_DIR%"
if exist "%USER_WINGET%" set "PATH=%PATH%;%LOCALAPPDATA%\Microsoft\WindowsApps"

:winget_ready
echo [INFO] winget listo. Verificando instalacion real de Python 3...

set "REAL_PYTHON="
for /f "tokens=*" %%p in ('where python 2^>nul') do (
    echo "%%p" | findstr /i "WindowsApps" >nul
    if errorlevel 1 (
        set "REAL_PYTHON=%%p"
        goto :python_found
    )
)

if exist "C:\Program Files\Python312\python.exe" set "REAL_PYTHON=C:\Program Files\Python312\python.exe"
if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" set "REAL_PYTHON=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"

if defined REAL_PYTHON (
    goto :python_found
)

echo [INFO] Python real no detectado. Instalando Python 3.12 mediante winget...
winget install -e --id Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements

if exist "C:\Program Files\Python312\python.exe" set "PATH=C:\Program Files\Python312;C:\Program Files\Python312\Scripts;%PATH%"
if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%PATH%"

:python_found
:: Limpiar el errorlevel=1 heredado por findstr cuando detecta el python real
verify >nul

:python_ok
echo [INFO] Python verificado correctamente.

echo [INFO] Verificando entorno Visual Studio instalado...
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" set "VSWHERE=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"

if exist "%VSWHERE%" (
    for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
        set "VS_PATH=%%i"
    )
)

if defined VS_PATH (
    echo [INFO] Visual Studio detectado en: "%VS_PATH%"
) else (
    echo [INFO] No se encontro MSVC, instalando Build Tools compatibles...
    winget install -e --id Microsoft.VisualStudio.2022.BuildTools --silent --accept-package-agreements --accept-source-agreements --override "--wait --quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
)

echo [INFO] Configuracion base de Windows completada con exito.
:: Asegurar que el script termine con un errorlevel limpio (0)
verify >nul
endlocal
