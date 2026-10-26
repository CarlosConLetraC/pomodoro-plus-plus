#!/usr/bin/env bash
set -euo pipefail
source common.sh

load_requirements

if [ -z "${REQUIREMENTS[ELECTRON_VERSION]:-}" ]; then
    prettyprint 2 "Error crítico: ELECTRON_VERSION no está definido en install/requirements.conf"
    exit 1
fi

ELEC_VER="${REQUIREMENTS[ELECTRON_VERSION]}"

prettyprint 0 "Instalando dependencias de sistema para Electron (pacman)..."
sudo pacman -Syu --noconfirm --needed \
    nss \
    nspr \
    gtk3 \
    libxss \
    alsa-lib \
    libcups \
    libdbus \
    libdrm \
    mesa \
    pango \
    cairo \
    expat \
    libxcomposite \
    libxdamage \
    libxrandr \
    libxfixes \
    libx11 \
    unzip

prettyprint 0 "Instalando localmente electron@${ELEC_VER} en el proyecto..."

if [ ! -f "package.json" ]; then
    npm init -y &> /dev/null
fi

npm install --save-dev "electron@${ELEC_VER}" || npm install --save-dev --ignore-scripts "electron@${ELEC_VER}"

ELECTRON_DIST_DIR="node_modules/electron/dist"

if [ ! -f "$ELECTRON_DIST_DIR/electron" ]; then
    prettyprint 1 "El descargador automático de npm falló. Obteniendo binario de Electron v${ELEC_VER} directamente..."
    
    mkdir -p "$ELECTRON_DIST_DIR"
    ELEC_URL="https://github.com/electron/electron/releases/download/v${ELEC_VER}/electron-v${ELEC_VER}-linux-x64.zip"
    
    prettyprint 0 "Descargando desde: $ELEC_URL"
    curl -fL "$ELEC_URL" -o /tmp/electron.zip
    
    prettyprint 0 "Extrayendo binarios de Electron..."
    unzip -qo /tmp/electron.zip -d "$ELECTRON_DIST_DIR"
    rm -f /tmp/electron.zip
fi

# CORRECCIÓN DE RUTA: Definir correctamente 'dist/electron' para que el index.js de npm lo ubique sin duplicaciones
echo "dist/electron" > "node_modules/electron/path.txt"

if [ -f "$ELECTRON_DIST_DIR/electron" ]; then
    chmod +x "$ELECTRON_DIST_DIR/electron"
fi

if [ -f "$ELECTRON_DIST_DIR/chrome-sandbox" ]; then
    sudo chown root:root "$ELECTRON_DIST_DIR/chrome-sandbox" || true
    sudo chmod 4755 "$ELECTRON_DIST_DIR/chrome-sandbox" || true
fi

prettyprint 0 "Verificación de Electron completada exitosamente:"
./node_modules/.bin/electron --version