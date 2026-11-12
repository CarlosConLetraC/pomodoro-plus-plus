#!/usr/bin/env bash
set -euo pipefail
source common.sh

export DEBIAN_FRONTEND=noninteractive

prettyprint 0 "Actualizando base de datos local de paquetes (APT) en Debian 13. . ."
sudo apt-get update

prettyprint 0 "Instalando dependencias base compartidas. . ."
sudo apt-get install -y --no-install-recommends \
    unzip \
    curl \
    make \
    gcc \
    ca-certificates \
    build-essential \
    python3

prettyprint 0 "Configuración base de Debian 13 completada con éxito."
