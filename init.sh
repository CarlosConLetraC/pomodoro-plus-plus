#!/usr/bin/env bash
set -euo pipefail
source common.sh

# Obtener la ruta absoluta del directorio del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Inyectar el entorno local de Node.js (.node_env) en el PATH de forma prioritaria
export PATH="$PROJECT_ROOT/.node_env/bin:$PATH"

prettyprint 0 "Entorno local cargado (.node_env/bin)"
prettyprint 0 "Verificando versiones locales..."
node -v
npm -v

# Verificar que Electron exista localmente
if [ ! -f "$PROJECT_ROOT/node_modules/.bin/electron" ]; then
    prettyprint 2 "Electron no está instalado en node_modules/.bin/. Ejecute ./setup.sh primero."
    exit 1
fi

prettyprint 0 "Lanzando la aplicación Electron. . ."

# Ejecutar Electron pasando el directorio actual (.) como app root
"$PROJECT_ROOT/node_modules/.bin/electron" "$PROJECT_ROOT" "$@"