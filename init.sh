#!/usr/bin/env bash
set -euo pipefail
source common.sh

# Obtener la ruta absoluta del directorio del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Inyectar el entorno local de Node.js (.node_env) en el PATH de forma prioritaria
export PATH="$PROJECT_ROOT/.node_env/bin:$PATH"

prettyprint 0 "Entorno local cargado (.node_env/bin)"
prettyprint 0 "Verificando versiones locales. . ."
node -v
npm -v

# Verificar que Electron exista localmente
if [ ! -f "$PROJECT_ROOT/node_modules/.bin/electron" ]; then
    prettyprint 2 "Electron no está instalado en node_modules/.bin/. Ejecute ./setup.sh primero."
    exit 1
fi

# Compilar TypeScript en el backend antes de arrancar
prettyprint 0 "Compilando fuentes de TypeScript del backend. . ."
npx tsc -p "$PROJECT_ROOT/src/backend/tsconfig.json"

# prettyprint 0 "Lanzando la aplicación Electron. . ."
# 
# # Ejecutar Electron pasando el directorio raíz del proyecto
# "$PROJECT_ROOT/node_modules/.bin/electron" "$PROJECT_ROOT" "$@"

prettyprint 0 "Lanzando la aplicación Electron (modo X11/Ozone). . ."

# Ejecutar Electron pasando el directorio raíz y forzando ozone-platform=x11
"$PROJECT_ROOT/node_modules/.bin/electron" "$PROJECT_ROOT" --ozone-platform=x11 "$@"