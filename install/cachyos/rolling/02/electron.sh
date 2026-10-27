#!/usr/bin/env bash
set -euo pipefail
source common.sh

load_requirements

if [ -z "${REQUIREMENTS[ELECTRON_VERSION]:-}" ]; then
    prettyprint 2 "Error crítico: ELECTRON_VERSION no está definido en install/requirements.conf"
    exit 1
fi

ELEC_VER="${REQUIREMENTS[ELECTRON_VERSION]}"

prettyprint 0 "Instalando dependencias de sistema para Electron (pacman). . ."
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
    libx11

prettyprint 0 "Instalando localmente electron@${ELEC_VER} en el proyecto. . ."

if [ ! -f "package.json" ]; then
    prettyprint 2 "Error crítico: No se encontró package.json en la raíz del proyecto."
    exit 1
fi

# Asegurar que el PATH incluya nuestro entorno local de Node
export PATH="$PWD/.node_env/bin:$PATH"

npm install --save-dev "electron@${ELEC_VER}" || npm install --save-dev --ignore-scripts "electron@${ELEC_VER}"

ELECTRON_DIST_DIR="node_modules/electron/dist"

if [ ! -f "$ELECTRON_DIST_DIR/electron" ]; then
    prettyprint 1 "Descargando binario oficial de Electron v${ELEC_VER} manualmente. . ."
    
    mkdir -p "$ELECTRON_DIST_DIR"
    ELEC_URL="https://github.com/electron/electron/releases/download/v${ELEC_VER}/electron-v${ELEC_VER}-linux-x64.zip"
    
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

# VALIDACIÓN ESTRICTA DE DIRECTORIO SRC (Sin hardcodeos ni fallbacks automáticos)
prettyprint 0 "Validando estructura modular existente en el directorio src/. . ."

if [ ! -d "src" ]; then
    prettyprint 2 "Error crítico: El directorio 'src/' no existe. Debes proveer la estructura modular de tu aplicación."
    exit 1
fi

if [ ! -f "src/index.js" ]; then
    prettyprint 2 "Error crítico: No se encontró 'src/index.js' (proceso principal de Electron requerido)."
    exit 1
fi

if [ ! -f "src/index.html" ]; then
    prettyprint 2 "Error crítico: No se encontró 'src/index.html' (vista de la aplicación requerida)."
    exit 1
fi

# Asegurar que el package.json apunte correctamente al index.js existente sin sobrescribir scripts ajenos
node -e '
const fs = require("fs");
const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
pkg.main = "src/index.js";
pkg.scripts = pkg.scripts || {};
if (!pkg.scripts.start) {
    pkg.scripts.start = "electron .";
}
fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2));
'

prettyprint 0 "Verificación completada exitosamente. Usando fuentes reales de src/:"
ls -la src/
./node_modules/.bin/electron --version