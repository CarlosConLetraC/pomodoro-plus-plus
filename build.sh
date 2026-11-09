#!/usr/bin/env bash
set -euo pipefail
source common.sh

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$PROJECT_ROOT/.node_env/bin:$PATH"

prettyprint 0 "Iniciando empaquetado de la aplicación (Modo Portable sin FUSE). . ."

if [ ! -f "$PROJECT_ROOT/node_modules/.bin/electron-builder" ]; then
    prettyprint 2 "Error: electron-builder no está instalado. Ejecuta ./setup.sh primero."
    exit 1
fi

prettyprint 0 "Compilando fuentes de TypeScript del backend. . ."
npx tsc -p "$PROJECT_ROOT/src/backend/tsconfig.json"

prettyprint 0 "Compilando estructura portable con electron-builder. . ."
"$PROJECT_ROOT/node_modules/.bin/electron-builder" --linux dir

UNPACKED_DIR="$PROJECT_ROOT/dist/linux-unpacked"
if [ -d "$UNPACKED_DIR" ]; then
    prettyprint 0 "Comprimiendo paquete portable en .tar.gz. . ."
    cd "$PROJECT_ROOT/dist"
    tar -czf "pomodoro-plus-plus-linux-x64.tar.gz" linux-unpacked
    cd "$PROJECT_ROOT"
fi

prettyprint 0 "Empaquetado completado con éxito."
prettyprint 0 "Entregable listo en 'dist/pomodoro-plus-plus-linux-x64.tar.gz'"
