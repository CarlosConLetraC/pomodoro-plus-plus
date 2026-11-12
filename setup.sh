#!/usr/bin/env bash
set -euo pipefail
source common.sh

# 1. Analizar argumentos pasados por línea de comandos (ej: os=debian os_version_id=13 arch=x64)
parse_args "$@"

BASE_PATH=$PWD

# Cargar información del OS (ahora respeta los argumentos CLI si se proporcionaron)
get_os_version

prettyprint 0 "Target OS: ${OS_INFO[NAME]} (${OS_INFO[ID]})"
prettyprint 0 "Version: ${OS_INFO[VERSION_ID]}"
if [ -n "${CLI_ARGS[arch]:-}" ]; then
    prettyprint 0 "Architecture Target: ${CLI_ARGS[arch]}"
fi

# Resolver la ruta raíz de las etapas para esta distribución/versión
first_stage_path=$(resolve_stage_dir 0)
stages_root="$BASE_PATH/$(dirname "$first_stage_path")"

if [ ! -d "$stages_root" ]; then
    prettyprint 2 "No se encontró el directorio de etapas para esta distribución: $stages_root"
    exit 1
fi

# Detectar automáticamente carpetas de etapas ([0-9][0-9]) ordenadas numéricamente
mapfile -t stage_dirs < <(find "$stages_root" -mindepth 1 -maxdepth 1 -type d -name '[0-9][0-9]' | sort)

if [ ${#stage_dirs[@]} -eq 0 ]; then
    prettyprint 1 "No se encontraron etapas de bootstrap configuradas en $stages_root"
    exit 0
fi

# Iterar dinámicamente sobre las etapas detectadas
for completeDir in "${stage_dirs[@]}"; do
    currentDir=$(basename "$completeDir")
    prettyprint 0 "Processing stage $currentDir ($completeDir)"
    run_stage_scripts "$completeDir"
done
