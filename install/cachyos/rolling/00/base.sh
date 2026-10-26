#!/usr/bin/env bash
set -euo pipefail
source common.sh

prettyprint 0 "Configurando pacman.conf para entorno de contenedor rootless. . ."

# Habilitar o insertar DisableSandboxNetwork de forma infalible bajo [options]
if grep -q "DisableSandboxNetwork" /etc/pacman.conf; then
    sudo sed -i 's/^#\?DisableSandboxNetwork.*/DisableSandboxNetwork/' /etc/pacman.conf
else
    sudo sed -i '/^\[options\]/a DisableSandboxNetwork' /etc/pacman.conf
fi

prettyprint 0 "Actualizando sistema y sincronizando base de datos local de paquetes. . ."
sudo pacman -Syu --noconfirm

prettyprint 0 "Instalando dependencias compartidas. . ."
sudo pacman -S unzip curl --noconfirm
