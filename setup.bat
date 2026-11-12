@echo off
setlocal enabledelayedexpansion

:: Obtener el directorio real del script anfitrión de forma robusta
set "PROJECT_ROOT=%~dp0"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

echo [INFO] Iniciando Bootstrap de Windows para Pomodoro Plus Plus...

set "REQ_FILE=%PROJECT_ROOT%\install\requirements.conf"
if not exist "%REQ_FILE%" (
    echo [FAIL] No se encontro %REQ_FILE%
    exit /b 1
)

:: Cargar variables desde install\requirements.conf
for /f "usebackq tokens=1,* delims==" %%A in ("%REQ_FILE%") do (
    set "KEY=%%A"
    set "VAL=%%B"
    :: Ignorar comentarios y lineas vacias
    if not "!KEY!"=="" if not "!KEY:~0,1!"=="#" (
        set "VAL=!VAL:"=!"
        set "!KEY!=!VAL!"
    )
)

echo [INFO] Configuracion cargada: Node v%NODE_VERSION% ^| Electron v%ELECTRON_VERSION% ^| SQLite v%SQLITE_VERSION%

:: Ejecutar etapas en orden
for %%S in (00 01 02 03) do (
    set "STAGE_DIR=%PROJECT_ROOT%\install\windows\rolling\%%S"
    if exist "!STAGE_DIR!" (
        echo.
        echo [INFO] === Ejecutando Etapa %%S ===
        for %%F in ("!STAGE_DIR!\*.bat") do (
            echo [INFO] --^> Ejecutando: %%~nxF
            call "%%F"
            if errorlevel 1 (
                echo [FAIL] Error critico en %%~nxF
                exit /b 1
            )
        )
    )
)

echo.
echo [INFO] Bootstrap de Windows completado con exito.
endlocal
