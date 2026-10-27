#!/usr/bin/env bash
set -euo pipefail
source common.sh

# NOTA: si desea usar las funciones auxiliares de podman, utilice `common.sh`.

BASE_PATH=$PWD
get_os_version
prettyprint 0 "Detected OS: ${OS_INFO[NAME]} (${OS_INFO[ID]})"
prettyprint 0 "Version: ${OS_INFO[VERSION_ID]}"

prettyprint 0 "Limpiando contenedores detenidos..."
podman container prune -f &>/dev/null || true

for file in "$BASE_PATH/dockers"/*.dockerfile; do
    filename=$(basename "$file" .dockerfile)
    # Eliminar la imagen previa si existe para forzar un build limpio
    if podman image exists "localhost/podman_${filename}"; then
        prettyprint 0 "Eliminando imagen anterior: podman_${filename}"
        podman rmi "localhost/podman_${filename}" &>/dev/null || true
    fi
done

prettyprint 0 "Iniciando construcción de nuevas imágenes..."
for file in "$BASE_PATH/dockers"/*.dockerfile; do
    filename=$(basename "$file" .dockerfile)
    podmanbuild "$file" "podman_${filename}"
done
