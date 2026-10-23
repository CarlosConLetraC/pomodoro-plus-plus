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
    
    # Normalizar 'arch' para que apunte a la carpeta 'archlinux' de tu árbol
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
