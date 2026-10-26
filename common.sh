#!/usr/bin/env bash

declare -A OS_INFO

function prettyprint() {
    local level=$1
    shift
    local packed=("$@")
    local currentTime=$(date +%H:%M:%S.%N)
    currentTime="${currentTime:0:12}"

    case $level in
        0)
            printf "[${currentTime}]\e[0;36m[INFO]:\e[0m %s\n" "${packed[*]}"
        ;;
        1)
            printf "[${currentTime}]\e[0;33m[WARN]:\e[0m %s\n" "${packed[*]}"
        ;;
        2|*)
            printf "[${currentTime}]\e[0;31m[FAIL]:\e[0m %s\n" "${packed[*]}"
        ;;
    esac
}

function get_os_version() {
    # Populate the global OS_INFO array
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        value="${value%\"}"
        value="${value#\"}"
        OS_INFO["$key"]="$value"
    done < /etc/os-release

    # Fallback for NAME if missing
    [[ -z "${OS_INFO[NAME]:-}" ]] && OS_INFO[NAME]="Unknown Linux"
    
    # Fallback for ID if missing
    [[ -z "${OS_INFO[ID]:-}" ]] && OS_INFO[ID]="unknown"

    # Priorizar BUILD_ID (como 'rolling') si existe; de lo contrario usar VERSION_ID o por defecto "rolling"
    if [[ -n "${OS_INFO[BUILD_ID]:-}" ]]; then
        OS_INFO[VERSION_ID]="${OS_INFO[BUILD_ID]}"
    elif [[ -z "${OS_INFO[VERSION_ID]:-}" ]]; then
        OS_INFO[VERSION_ID]="rolling"
    fi

    # Fallback for VERSION (Use PRETTY_NAME or VERSION_ID if VERSION is missing)
    if [[ -z "${OS_INFO[VERSION]:-}" ]]; then
        OS_INFO[VERSION]="${OS_INFO[PRETTY_NAME]:-${OS_INFO[VERSION_ID]}}"
    fi
}

function resolve_stage_dir() {
    local stage_num=$1
    local stage_dir_name=$(printf "%.2d" "$stage_num")
    local id="${OS_INFO[ID]:-unknown}"
    
    # Normalizar 'arch' para que apunte a la carpeta 'archlinux'. . .
    if [ "$id" = "arch" ]; then
        id="archlinux"
    fi
    
    local version="${OS_INFO[VERSION_ID]:-rolling}"
    local target_dir="install/$id/$version/$stage_dir_name"
    echo "$target_dir"
}

function podmanbuild() {
    if [ -z "$1" ]; then
        prettyprint 2 "Uso: podmanbuild <dockerfile> [tag]"
        return 1
    fi

    local input_file="$1"
    local tag="$2"
    local dockerfile=""

    # Resolve Dockerfile path intelligently:
    if [ -f "$input_file" ]; then
        dockerfile="$input_file"
    elif [ -f "dockers/$input_file" ]; then
        dockerfile="dockers/$input_file"
    elif [ -f "dockers/${input_file}.dockerfile" ]; then
        dockerfile="dockers/${input_file}.dockerfile"
    else
        prettyprint 2 "No se encuentra el Dockerfile: $input_file"
        return 1
    fi

    # If tag is not provided, automatically generate one from the filename
    if [ -z "$tag" ]; then
        tag=$(basename "$dockerfile" .dockerfile)
    fi

    local host_user=$(whoami)
    local host_uid=$(id -u)
    local host_gid=$(id -g)

    prettyprint 0 "Build: $tag <- $dockerfile (User: $host_user, UID: $host_uid)"

    podman build \
        --build-arg USERNAME="$host_user" \
        --build-arg USER_UID="$host_uid" \
        --build-arg USER_GID="$host_gid" \
        -t "$tag" -f "$dockerfile" .
}

function podmanrun() {
    oldPWD="$(pwd)"
    cd ~

    if [ -z "$1" ]; then
        prettyprint 2 "Uso: podmanrun <imagen>"
    	cd "$oldPWD"
        return 1
    fi

    local image="$1"
    local user=$(whoami)

    podman run -it \
        --userns=keep-id \
        -v "$(pwd):/home/${user}:Z" \
        -w "/home/${user}" \
        "$image"

    cd "$oldPWD"
}

function init() {
    local script_path="$1"
    prettyprint 0 "Inicializando especificaciones para: $(basename "$script_path")"
    
    # Activar automáticamente el entorno local de Node/npm si existe. . .
    local local_node_bin="$PWD/.node_env/bin"
    if [ -d "$local_node_bin" ]; then
        export PATH="$local_node_bin:$PATH"
    fi
}

function run_stage_scripts() {
    local stage_dir="$1"
    
    # Verificar si existen archivos .sh en la etapa
    if compgen -G "$stage_dir/*.sh" > /dev/null; then
        # Ordenar y ejecutar cada script .sh encontrado en la etapa
        for script in $(ls "$stage_dir"/*.sh | sort); do
            if [ -f "$script" ]; then
                prettyprint 0 "--> Ejecutando script: $(basename "$script")"
                init "$script"
                # Ejecutar el script manteniendo el control de errores del padre
                bash "$script"
            fi
        done
    else
        prettyprint 1 "No se encontraron scripts .sh en la etapa $(basename "$stage_dir")"
    fi
}

declare -A REQUIREMENTS

function load_requirements() {
    local req_file="install/requirements.conf"
    
    if [ ! -f "$req_file" ]; then
        prettyprint 2 "Error crítico: No se encontró el archivo de requerimientos en $req_file"
        exit 1
    fi

    # Limpiar el array por si se recarga
    REQUIREMENTS=()

    while IFS='=' read -r key value; do
        # Ignorar comentarios y líneas vacías
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        
        # Eliminar espacios en blanco alrededor de las claves y valores
        key="$(echo "$key" | xargs)"
        value="$(echo "$value" | xargs)"
        
        # Remover comillas dobles o simples si las tuviera
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"
        
        REQUIREMENTS["$key"]="$value"
    done < "$req_file"

    prettyprint 0 "Requerimientos leídos exitosamente desde $req_file"
}
