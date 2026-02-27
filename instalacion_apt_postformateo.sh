#!/usr/bin/env bash

# Instalacion post-formateo por bloques (APT).
# Ejecuta las lineas que quieras, en el orden que prefieras.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALIASES_SOURCE="$SCRIPT_DIR/bashrc aliases.sh"
ALIASES_TARGET="$HOME/.bash_aliases"
BASHRC_TARGET="$HOME/.bashrc"
DMRC_TARGET="$HOME/.dmrc"

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
  hyphen-es mythes-es

# 4) Python / utilidades para CLI
sudo apt-get install -y python3-pip pipx
pipx ensurepath
pipx install tldr

# 5) Al final
sudo apt-get autoremove --purge -y
sudo apt-get clean

# 6) Migrar aliases de este repo a ~/.bash_aliases
if [ -f "$ALIASES_SOURCE" ]; then
  if [ -f "$ALIASES_TARGET" ]; then
    backup="$ALIASES_TARGET.bak_$(date +%Y%m%d_%H%M%S)"
    cp "$ALIASES_TARGET" "$backup"
    echo "Backup de ~/.bash_aliases: $backup"
  fi

  cp "$ALIASES_SOURCE" "$ALIASES_TARGET"
  echo "Aliases copiados en: $ALIASES_TARGET"

  if [ -f "$BASHRC_TARGET" ] && ! grep -Fq '[ -f ~/.bash_aliases ]' "$BASHRC_TARGET"; then
    cat >> "$BASHRC_TARGET" <<'EOF'

# Cargar aliases personalizados
if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi
EOF
    echo "Se agrego carga de ~/.bash_aliases en ~/.bashrc"
  fi

  # shellcheck disable=SC1090
  . "$ALIASES_TARGET"
  echo "Aliases cargados en la sesion actual."
else
  echo "No se encontro archivo de aliases: $ALIASES_SOURCE"
fi

# 7) Preferir Wayland a nivel usuario (sin tocar GDM global)
if [ -f "$DMRC_TARGET" ]; then
  dmrc_backup="$DMRC_TARGET.bak_$(date +%Y%m%d_%H%M%S)"
  cp "$DMRC_TARGET" "$dmrc_backup"
  echo "Backup de ~/.dmrc: $dmrc_backup"
fi

cat > "$DMRC_TARGET" <<'EOF'
[Desktop]
Session=ubuntu
EOF
chmod 644 "$DMRC_TARGET"
echo "Preferencia de sesion configurada: Wayland (usuario)."
echo "Si algo falla, en login elige: Ubuntu on Xorg."
