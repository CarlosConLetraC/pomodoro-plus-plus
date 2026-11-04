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

prettyprint 0 "Descomprimiendo código fuente en el backend. . ."
tar -xzf "$BACKEND_NATIVE_DIR/sqlite-autoconf.tar.gz" --strip-components=1 -C "$BACKEND_NATIVE_DIR/sqlite-src"

prettyprint 0 "Subsistema SQLite embebido configurado con éxito para la capa C/C++."