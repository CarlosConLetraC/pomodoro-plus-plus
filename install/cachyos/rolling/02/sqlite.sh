#!/usr/bin/env bash
set -euo pipefail
source common.sh

load_requirements

if [ -z "${REQUIREMENTS[SQLITE_VERSION]:-}" ] || [ -z "${REQUIREMENTS[SQLITE_TAR_VERSION]:-}" ]; then
    prettyprint 2 "Error crítico: SQLITE_VERSION o SQLITE_TAR_VERSION no están definidas en requirements.conf"
    exit 1
fi

SQLITE_VERSION="${REQUIREMENTS[SQLITE_VERSION]}"
SQLITE_TAR_VERSION="${REQUIREMENTS[SQLITE_TAR_VERSION]}"
SQLITE_URL="https://www.sqlite.org/2026/sqlite-autoconf-${SQLITE_TAR_VERSION}.tar.gz"
BACKEND_NATIVE_DIR="src/backend/native"

prettyprint 0 "Preparando subsistema nativo SQLite versión $SQLITE_VERSION. . ."

mkdir -p "$BACKEND_NATIVE_DIR/sqlite-src"

if [ ! -f "$BACKEND_NATIVE_DIR/sqlite-autoconf.tar.gz" ]; then
    prettyprint 0 "Descargando código fuente de SQLite desde el mirror oficial. . ."
    curl -L "$SQLITE_URL" -o "$BACKEND_NATIVE_DIR/sqlite-autoconf.tar.gz"
fi

# Verificación de idempotencia: solo extrae si el código fuente no ha sido descomprimido antes
if [ ! -f "$BACKEND_NATIVE_DIR/sqlite-src/sqlite3.c" ]; then
    prettyprint 0 "Descomprimiendo código fuente en el backend. . ."
    tar -xzf "$BACKEND_NATIVE_DIR/sqlite-autoconf.tar.gz" --strip-components=1 -C "$BACKEND_NATIVE_DIR/sqlite-src"
else
    prettyprint 0 "El código fuente de SQLite ya se encuentra descomprimido."
fi

prettyprint 0 "Creando/Actualizando src/backend/native/binding.gyp. . ."

cat << 'EOF' > "$BACKEND_NATIVE_DIR/binding.gyp"
{
  "targets": [
    {
      "target_name": "sqlite_native",
      "sources": [
        "sqlite_addon.cpp",
        "sqlite-src/sqlite3.c"
      ],
      "include_dirs": [
        "sqlite-src",
        "../../../node_modules/node-addon-api"
      ],
      "defines": [
        "SQLITE_THREADSAFE=1",
        "SQLITE_ENABLE_FTS5=1",
        "NAPI_DISABLE_CPP_EXCEPTIONS"
      ],
      "cflags!": [ "-fno-exceptions" ],
      "cflags_cc!": [ "-fno-exceptions" ]
    }
  ]
}
EOF

# Automatización de la compilación nativa utilizando el entorno aislado de node_env
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export PATH="$PROJECT_ROOT/.node_env/bin:$PATH"

prettyprint 0 "Entorno local cargado para compilación (.node_env/bin)"
prettyprint 0 "Verificando herramientas locales para node-gyp. . ."
node -v
npm -v

# Asegurar que node-addon-api esté instalado ANTES de ejecutar node-gyp configure
if [ ! -d "node_modules/node-addon-api" ]; then
    prettyprint 0 "Instalando dependencia node-addon-api. . ."
    npm install node-addon-api
else
    prettyprint 0 "La dependencia node-addon-api ya está instalada."
fi

if [ ! -f "$BACKEND_NATIVE_DIR/sqlite_addon.cpp" ]; then
    prettyprint 1 "Aviso: Falta crear 'sqlite_addon.cpp' en $BACKEND_NATIVE_DIR para completar la compilación de node-gyp."
else
    prettyprint 0 "Compilando módulo nativo de SQLite con node-gyp. . ."
    cd "$BACKEND_NATIVE_DIR"
    
    # Limpieza, configuración y compilación segura en cada ejecución
    npx node-gyp clean
    npx node-gyp configure
    npx node-gyp build
    
    cd "$PROJECT_ROOT"
    prettyprint 0 "Módulo nativo sqlite_native.node compilado con éxito."
fi
