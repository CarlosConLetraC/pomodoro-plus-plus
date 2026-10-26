#!/usr/bin/env bash
set -euo pipefail
source common.sh
load_requirements

# Validar estrictamente que las variables requeridas existan en el archivo de configuración
if [ -z "${REQUIREMENTS[NODE_VERSION]:-}" ] || [ -z "${REQUIREMENTS[ARCH]:-}" ]; then
    prettyprint 2 "Faltan parámetros críticos (NODE_VERSION o ARCH) en install/requirements.conf"
    exit 1
fi

NODE_VER="${REQUIREMENTS[NODE_VERSION]}"
SYS_ARCH="${REQUIREMENTS[ARCH]}"

LOCAL_NODE_DIR="$PWD/.node_env"

prettyprint 0 "Instalando Node.js v${NODE_VER} (${SYS_ARCH}) localmente en $LOCAL_NODE_DIR (estilo .venv)..."

mkdir -p "$LOCAL_NODE_DIR"

# Construcción de la URL completamente dinámica según requirements.conf
NODE_URL="https://nodejs.org/dist/v${NODE_VER}/node-v${NODE_VER}-linux-${SYS_ARCH}.tar.xz"

prettyprint 0 "Descargando desde: $NODE_URL"
# Extracción local sin requerir privilegios de superusuario (sudo) en el sistema
curl -fsSL "$NODE_URL" | tar -xJ -C "$LOCAL_NODE_DIR" --strip-components=1

# Configurar el PATH para la sesión actual del script
export PATH="$LOCAL_NODE_DIR/bin:$PATH"

prettyprint 0 "Verificación de la instalación local:"
node -v
npm -v
