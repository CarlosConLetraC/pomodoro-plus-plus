#!/usr/bin/env bash
set -euo pipefail
source common.sh

# NOTA: si desea usar las funciones auxiliares de podman, utilice `common.sh`.

BASE_PATH=$PWD
get_os_version
prettyprint 0 "Detected OS: ${OS_INFO[NAME]} (${OS_INFO[ID]})"
prettyprint 0 "Version: ${OS_INFO[VERSION_ID]}"

prettyprint 0 "Limpiando contenedores detenidos. . ."
podman container prune -f &>/dev/null || true

# Verificar si se pasó un argumento con la ruta/nombre del Dockerfile
if [ $# -gt 0 ]; then
    target_arg="$1"
    dockerfile=""

    # Resolver la ruta del Dockerfile flexiblemente
    if [ -f "$target_arg" ]; then
        dockerfile="$target_arg"
    elif [ -f "$BASE_PATH/$target_arg" ]; then
        dockerfile="$BASE_PATH/$target_arg"
    elif [ -f "$BASE_PATH/dockers/$target_arg" ]; then
        dockerfile="$BASE_PATH/dockers/$target_arg"
    elif [ -f "$BASE_PATH/dockers/${target_arg}.dockerfile" ]; then
        dockerfile="$BASE_PATH/dockers/${target_arg}.dockerfile"
    else
        prettyprint 2 "No se encuentra el Dockerfile especificado: $target_arg"
        exit 1
    fi

    filename=$(basename "$dockerfile" .dockerfile)

    # Eliminar la imagen previa si existe para forzar un build limpio de esa imagen
    if podman image exists "localhost/podman_${filename}"; then
        prettyprint 0 "Eliminando imagen anterior: podman_${filename}"
        podman rmi "localhost/podman_${filename}" &>/dev/null || true
    fi

    prettyprint 0 "Iniciando construcción de la imagen específica: ${filename} . . ."
    podmanbuild "$dockerfile" "podman_${filename}"

else
    # Comportamiento por defecto: compilar todos los Dockerfiles si no hay argumentos
    for file in "$BASE_PATH/dockers"/*.dockerfile; do
        filename=$(basename "$file" .dockerfile)
        if podman image exists "localhost/podman_${filename}"; then
            prettyprint 0 "Eliminando imagen anterior: podman_${filename}"
            podman rmi "localhost/podman_${filename}" &>/dev/null || true
        fi
    done

    prettyprint 0 "Iniciando construcción de todas las nuevas imágenes. . ."
    for file in "$BASE_PATH/dockers"/*.dockerfile; do
        filename=$(basename "$file" .dockerfile)
        podmanbuild "$file" "podman_${filename}"
    done
fi
