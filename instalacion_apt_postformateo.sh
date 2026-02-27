#!/usr/bin/env bash

# Instalacion post-formateo por bloques (APT).
# Ejecuta las lineas que quieras, en el orden que prefieras.

# Recomendado: primero
sudo apt-get update

# 1) Herramientas base de terminal
sudo apt-get install -y \
  curl wget git gh ripgrep xclip fzf lsd \
  software-properties-common ca-certificates gnupg2

# 2) GNOME y personalizacion de ventanas/extensiones
sudo apt-get install -y \
  gnome-shell-extension-manager gnome-shell-extensions dconf-cli

# 3) Idioma ES + tipografias
sudo apt-get install -y \
  fonts-jetbrains-mono \
  language-pack-es language-pack-gnome-es \
  hyphen-es mythes-es \

# 4) Python / utilidades para CLI
sudo apt-get install -y python3-pip pipx
pipx ensurepath
pipx install tldr

# 5) Al final
sudo apt-get autoremove --purge -y
sudo apt-get clean
