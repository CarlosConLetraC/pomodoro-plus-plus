#!/usr/bin/env bash
set -euo pipefail
source common.sh

load_requirements

if [ -z "${REQUIREMENTS[ELECTRON_VERSION]:-}" ]; then
    prettyprint 2 "Error crítico: ELECTRON_VERSION no está definido en install/requirements.conf"
    exit 1
fi

ELEC_VER="${REQUIREMENTS[ELECTRON_VERSION]}"
ARCH="${REQUIREMENTS[ARCH]}"

export DEBIAN_FRONTEND=noninteractive

prettyprint 0 "Instalando dependencias de sistema para Electron (apt-get) en Debian 13. . ."
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libasound2t64 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libx11-xcb1 \
    libxcb-dri3-0 \
    libxss1 \
    libxtst6 \
    xdg-utils

prettyprint 0 "Instalando localmente electron@${ELEC_VER} en el proyecto. . ."

# Generación automática de package.json si no existe previamente
if [ ! -f "package.json" ]; then
    prettyprint 1 "No se encontró package.json. Generando package.json base automáticamente. . ."
    cat << 'EOF' > package.json
{
  "name": "pomodoro-plus-plus",
  "version": "1.0.0",
  "description": "Pomodoro Plus Plus App",
  "main": "src/backend/index.js",
  "scripts": {
    "start": "electron .",
    "build:linux": "electron-builder --linux dir",
    "build:win": "electron-builder --win nsis"
  },
  "devDependencies": {
    "electron": "^45.0.0",
    "electron-builder": "^24.13.3"
  },
  "build": {
    "appId": "com.pomodoro.app",
    "productName": "Pomodoro Plus Plus",
    "directories": {
        "output": "dist"
    },
    "files": [
        "src/**/*",
        "package.json"
    ],
    "asarUnpack": [
        "**/*.node"
    ],
    "linux": {
        "target": ["dir"],
        "category": "Utility"
    },
    "win": {
        "target": ["nsis"],
        "icon": "src/frontend/assets/icon.png"
    },
    "nsis": {
        "oneClick": false,
        "allowToChangeInstallationDirectory": true,
        "installerIcon": "src/frontend/assets/icon.png",
        "uninstallerIcon": "src/frontend/assets/icon.png",
        "createDesktopShortcut": true,
        "createStartMenuShortcut": true,
        "shortcutName": "Pomodoro Plus Plus"
    }
  }
}
EOF
else
    prettyprint 0 "package.json detectado correctamente."
fi

export PATH="$PWD/.node_env/bin:$PATH"

npm install --save-dev "electron@${ELEC_VER}" || npm install --save-dev --ignore-scripts "electron@${ELEC_VER}"

ELECTRON_DIST_DIR="node_modules/electron/dist"

if [ ! -f "$ELECTRON_DIST_DIR/electron" ]; then
    prettyprint 1 "Descargando binario oficial de Electron v${ELEC_VER} manualmente. . ."
    
    mkdir -p "$ELECTRON_DIST_DIR"
    ELEC_URL="https://github.com/electron/electron/releases/download/v${ELEC_VER}/electron-v${ELEC_VER}-linux-${ARCH}.zip"
    
    prettyprint 0 "Descargando desde: $ELEC_URL"
    curl -fL "$ELEC_URL" -o /tmp/electron.zip
    
    prettyprint 0 "Extrayendo binarios de Electron. . ."
    unzip -qo /tmp/electron.zip -d "$ELECTRON_DIST_DIR"
    rm -f /tmp/electron.zip
fi

# CORRECCIÓN DE RUTA: El index.js de electron busca a partir de 'dist/', 
# por lo que path.txt debe contener únicamente 'electron'.
printf "electron" > "node_modules/electron/path.txt"

if [ -f "$ELECTRON_DIST_DIR/electron" ]; then
    chmod +x "$ELECTRON_DIST_DIR/electron"
fi

if [ -f "$ELECTRON_DIST_DIR/chrome-sandbox" ]; then
    sudo chown root:root "$ELECTRON_DIST_DIR/chrome-sandbox" || true
    sudo chmod 4755 "$ELECTRON_DIST_DIR/chrome-sandbox" || true
fi

# INSTALACIÓN/VERIFICACIÓN DE ELECTRON-BUILDER
prettyprint 0 "Verificando disponibilidad de electron-builder para empaquetado final. . ."
if [ ! -f "node_modules/.bin/electron-builder" ]; then
    prettyprint 1 "electron-builder no detectado. Instalando dependencia dev localmente. . ."
    ./.node_env/bin/npm install --save-dev electron-builder
else
    prettyprint 0 "electron-builder ya se encuentra instalado localmente."
fi

# VALIDACIÓN ESTRICTA DE DIRECTORIO SRC
prettyprint 0 "Validando estructura modular existente en el directorio src/. . ."

if [ ! -d "src" ]; then
    prettyprint 2 "Error crítico: El directorio 'src/' no existe. Debes proveer la estructura modular de su aplicación."
    exit 1
fi

if [ ! -d "src/backend" ]; then
    prettyprint 2 "Error crítico: El directorio 'src/backend/' no existe. Debes proveer la estructura modular de su aplicación."
    exit 1
fi

if [ ! -f "src/backend/index.js" ]; then
    prettyprint 2 "Error crítico: No se encontró 'src/backend/index.js' (proceso principal de Electron requerido)."
    exit 1
fi

if [ ! -f "src/frontend/index.html" ]; then
    prettyprint 2 "Error crítico: No se encontró 'src/frontend/index.html' (vista de la aplicación requerida)."
    exit 1
fi

prettyprint 0 "Verificación y aprovisionamiento de Electron completados exitosamente."
