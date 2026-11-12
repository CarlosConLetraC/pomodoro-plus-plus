#!/usr/bin/env bash
set -euo pipefail
source common.sh

# Cargar las rutas centralizadas según el perfil del SO
load_paths

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNPACKED_DIR="$PROJECT_ROOT/${DEPLOY_PATHS[DIST_DIR]}/linux-unpacked"

if [ ! -d "$UNPACKED_DIR" ]; then
    prettyprint 2 "No se encontró el directorio compilado en '$UNPACKED_DIR'."
    prettyprint 1 "Ejecuta './build.sh' primero antes de instalar."
    exit 1
fi

INSTALL_DIR="${DEPLOY_PATHS[APP_DIR]}"
BIN_DIR="${DEPLOY_PATHS[BIN_DIR]}"
BIN_LINK="$BIN_DIR/pomodoro-plus-plus"
DESKTOP_FILE="$HOME/.local/share/applications/pomodoro-plus-plus.desktop"
ICON_DEST="$HOME/.local/share/icons/hicolor/512x512/apps/pomodoro-plus-plus.png"
ICON_SRC="$PROJECT_ROOT/src/frontend/assets/icon.png"

prettyprint 0 "Iniciando la instalación de Pomodoro Plus Plus. . ."

if [ -d "$INSTALL_DIR" ]; then
    prettyprint 1 "Directorio previo detectado en $INSTALL_DIR. Actualizando. . ."
    rm -rf "$INSTALL_DIR"
fi

prettyprint 0 "Copiando archivos compilados a $INSTALL_DIR. . ."
mkdir -p "$INSTALL_DIR"
cp -r "$UNPACKED_DIR"/* "$INSTALL_DIR/"

prettyprint 0 "Ajustando permisos y configurando sandbox. . ."
find "$INSTALL_DIR" -type d -exec chmod 755 {} +
find "$INSTALL_DIR" -type f -exec chmod 644 {} +
chmod +x "$INSTALL_DIR/pomodoro-plus-plus"

if [ -f "$INSTALL_DIR/chrome-sandbox" ]; then
    chown root:root "$INSTALL_DIR/chrome-sandbox" 2>/dev/null || true
    chmod 4755 "$INSTALL_DIR/chrome-sandbox" 2>/dev/null || true
fi

prettyprint 0 "Configurando el lanzador global en $BIN_LINK. . ."
mkdir -p "$BIN_DIR"
cat << EOF > "$BIN_LINK"
#!/usr/bin/env bash
export ELECTRON_OZONE_PLATFORM_HINT=x11
exec "${INSTALL_DIR}/pomodoro-plus-plus" --ozone-platform=x11 "\$@"
EOF
chmod +x "$BIN_LINK"

if [ -f "$ICON_SRC" ]; then
    prettyprint 0 "Copiando icono del sistema a $ICON_DEST. . ."
    mkdir -p "$(dirname "$ICON_DEST")"
    cp "$ICON_SRC" "$ICON_DEST"
    chmod 644 "$ICON_DEST"
    ICON_FIELD="Icon=pomodoro-plus-plus"
else
    prettyprint 1 "No se encontró el icono en $ICON_SRC, usando icono por defecto."
    ICON_FIELD="Icon=utilities-timer"
fi

prettyprint 0 "Registrando la aplicación en el entorno de escritorio. . ."
mkdir -p "$(dirname "$DESKTOP_FILE")"
cat << EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=Pomodoro Plus Plus
Comment=Aplicación de productividad Pomodoro avanzada
Exec=${BIN_LINK} %U
Terminal=false
Type=Application
Categories=Utility;Timer;Office;
StartupNotify=true
${ICON_FIELD}
EOF

chmod 644 "$DESKTOP_FILE"

if command -v update-desktop-database &> /dev/null; then
    prettyprint 0 "Actualizando base de datos de escritorios. . ."
    update-desktop-database -q "$HOME/.local/share/applications" || true
fi

prettyprint 0 "¡Instalación completada con éxito!"
prettyprint 0 "Ya puedes ejecutar 'pomodoro-plus-plus' desde tu terminal o buscarlo en tu menú de aplicaciones."
