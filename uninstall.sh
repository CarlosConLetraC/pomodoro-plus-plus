#!/usr/bin/env bash
set -euo pipefail
source common.sh

load_install_config

if [ "$EUID" -ne 0 ]; then
    prettyprint 2 "Este script debe ejecutarse con privilegios de administrador (sudo ./uninstall.sh)"
    exit 1
fi

INSTALL_DIR="${INSTALL_CONFIG[INSTALL_DIR]}"
BIN_LINK="${INSTALL_CONFIG[BIN_LINK]}"
DESKTOP_FILE="${INSTALL_CONFIG[DESKTOP_FILE]}"
ICON_DEST="${INSTALL_CONFIG[ICON_DEST]}"

prettyprint 0 "Iniciando la desinstalación de ${INSTALL_CONFIG[PRODUCT_NAME]}. . ."

if [ -d "$INSTALL_DIR" ]; then
    prettyprint 0 "Eliminando directorio de instalación $INSTALL_DIR. . ."
    rm -rf "$INSTALL_DIR"
fi

if [ -L "$BIN_LINK" ] || [ -f "$BIN_LINK" ]; then
    prettyprint 0 "Eliminando lanzador del sistema $BIN_LINK. . ."
    rm -f "$BIN_LINK"
fi

if [ -f "$DESKTOP_FILE" ]; then
    prettyprint 0 "Eliminando archivo de escritorio $DESKTOP_FILE. . ."
    rm -f "$DESKTOP_FILE"
fi

if [ -f "$ICON_DEST" ]; then
    prettyprint 0 "Eliminando icono del sistema $ICON_DEST. . ."
    rm -f "$ICON_DEST"
fi

if command -v update-desktop-database &> /dev/null; then
    update-desktop-database -q
fi

prettyprint 0 "¡Desinstalación completada con éxito!"
