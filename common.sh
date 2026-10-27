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
    if [ ! -f /etc/os-release ]; then
        prettyprint 2 "Error crítico: No se encontró /etc/os-release en el sistema."
        exit 1
    fi

    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        value="${value%\"}"
        value="${value#\"}"
        OS_INFO["$key"]="$value"
    done < /etc/os-release

    if [ -z "${OS_INFO[ID]:-}" ]; then
        prettyprint 2 "Error crítico: El identificador ID del sistema operativo no está definido."
        exit 1
    fi

    if [[ -n "${OS_INFO[BUILD_ID]:-}" ]]; then
        OS_INFO[VERSION_ID]="${OS_INFO[BUILD_ID]}"
    elif [ -z "${OS_INFO[VERSION_ID]:-}" ]; then
        OS_INFO[VERSION_ID]="rolling"
    fi
}

function resolve_stage_dir() {
    local stage_num=$1
    local stage_dir_name=$(printf "%.2d" "$stage_num")
    local id="${OS_INFO[ID]}"
    
    if [ "$id" = "arch" ]; then
        id="archlinux"
    fi
    
    local version="${OS_INFO[VERSION_ID]}"
    local target_dir="install/$id/$version/$stage_dir_name"

    if [ ! -d "$target_dir" ]; then
        prettyprint 2 "Error crítico: No existe la ruta de etapas estricta para $id ($version) en $target_dir"
        exit 1
    fi

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
    if [ -z "$1" ]; then
        prettyprint 2 "Uso: podmanrun <imagen>"
        return 1
    fi

    local image="$1"
    local user=$(whoami)
    local host_home=""
    local current_pwd="$(pwd)"
    local container_workdir=""

    if grep -qEi "(microsoft|wsl)" /proc/version &>/dev/null; then
        prettyprint 0 "Entorno WSL detectado."
        host_home="/mnt/c/Users/${user}"
    else
        prettyprint 0 "Entorno Linux nativo detectado."
        host_home="$HOME"
    fi

    if [[ "$current_pwd" == "$host_home"* ]]; then
        local relative_path="${current_pwd#$host_home}"
        container_workdir="/home/${user}${relative_path}"
    else
        container_workdir="/home/${user}"
    fi

    prettyprint 0 "Montando directorio base: $host_home -> /home/${user}"
    prettyprint 0 "Posicionándose en el path equivalente: $container_workdir"

    podman run -it \
        --userns=keep-id \
        -v "$host_home:/home/${user}:Z" \
        -w "$container_workdir" \
        "$image"
}

function init() {
    local script_path="$1"
    prettyprint 0 "Inicializando especificaciones para: $(basename "$script_path")"
    
    local local_node_bin="$PWD/.node_env/bin"
    if [ -d "$local_node_bin" ]; then
        export PATH="$local_node_bin:$PATH"
    fi
}

function run_stage_scripts() {
    local stage_dir="$1"
    
    if compgen -G "$stage_dir/*.sh" > /dev/null; then
        for script in $(ls "$stage_dir"/*.sh | sort); do
            if [ -f "$script" ]; then
                prettyprint 0 "--> Ejecutando script: $(basename "$script")"
                init "$script"
                bash "$script"
            fi
        done
    else
        prettyprint 2 "Error crítico: No se encontraron scripts .sh obligatorios en la etapa $(basename "$stage_dir")"
        exit 1
    fi
}

declare -A REQUIREMENTS

function load_requirements() {
    local req_file="install/requirements.conf"
    
    if [ ! -f "$req_file" ]; then
        prettyprint 2 "Error crítico: No se encontró el archivo de requerimientos en $req_file"
        exit 1
    fi

    REQUIREMENTS=()

    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        
        key="$(echo "$key" | xargs)"
        value="$(echo "$value" | xargs)"
        
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"
        
        REQUIREMENTS["$key"]="$value"
    done < "$req_file"

    prettyprint 0 "Requerimientos leídos exitosamente desde $req_file"
}
