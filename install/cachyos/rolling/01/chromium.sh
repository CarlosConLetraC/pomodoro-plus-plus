#!/usr/bin/env bash
set -euo pipefail
source common.sh

load_requirements

if [ -z "${REQUIREMENTS[CHROMIUM_VERSION]:-}" ]; then
    prettyprint 2 "Error crítico: CHROMIUM_VERSION no está definido en install/requirements.conf"
    exit 1
fi

CHROMIUM_VER="${REQUIREMENTS[CHROMIUM_VERSION]}"
prettyprint 0 "Configurando el entorno para la compilación de Chromium v${CHROMIUM_VER} desde código fuente. . ."

# 1. Instalar dependencias del sistema requeridas para compilar Chromium en Arch/CachyOS
prettyprint 0 "Instalando dependencias de compilación para Chromium (pacman). . ."
sudo pacman -Syu --noconfirm --needed \
    base-devel \
    git \
    python \
    perl \
    inetutils \
    gperf \
    bison \
    ninja \
    pkgconf \
    alsa-lib \
    gtk3 \
    nss \
    libcups \
    libxss \
    libxi \
    libxtst

# 2. Configurar depot_tools de Google localmente dentro del proyecto ($PWD)
DEPOT_TOOLS_DIR="$PWD/depot_tools"
if [ ! -d "$DEPOT_TOOLS_DIR" ]; then
    prettyprint 0 "Clonando Google depot_tools localmente en el proyecto. . ."
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "$DEPOT_TOOLS_DIR"
fi

# Exportar depot_tools local al PATH de la sesión actual
export PATH="$DEPOT_TOOLS_DIR:$PATH"

# 3. Preparar directorio de código fuente de Chromium
CHROMIUM_SRC_DIR="$PWD/chromium_src"
mkdir -p "$CHROMIUM_SRC_DIR"
cd "$CHROMIUM_SRC_DIR"

if [ ! -d "src" ]; then
    prettyprint 0 "Inicializando configuración de gclient para Chromium. . ."
    gclient config "https://chromium.googlesource.com/chromium/src.git"
    
    prettyprint 1 "Aviso: La sincronización del código fuente de Chromium es masiva y puede tardar dependiendo de su red."
    gclient sync --with_branch_heads --no-history
else
    cd src
    prettyprint 0 "Ejecutando gclient runhooks para asegurar la generación de archivos de versión. . ."
    gclient runhooks
    cd ..
fi

cd src
SYS_ARCH="${REQUIREMENTS[ARCH]}"

# Generar argumentos de compilación optimizados con GN
prettyprint 0 "Generando archivos de configuración de compilación con GN. . ."
gn gen out/Default --args="is_debug=false symbol_level=0 target_cpu=\"${SYS_ARCH}\""

prettyprint 0 "Entorno de Chromium preparado localmente. Listo para iniciar compilación."