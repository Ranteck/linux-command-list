#!/usr/bin/env bash

# Instalacion post-formateo por bloques (APT).
# Ejecuta las lineas que quieras, en el orden que prefieras.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALIASES_SOURCE="$SCRIPT_DIR/bashrc aliases.sh"
ALIASES_TARGET="$HOME/.bash_aliases"
BASHRC_TARGET="$HOME/.bashrc"
DMRC_TARGET="$HOME/.dmrc"
SLACK_WRAPPER_TARGET="$HOME/.local/bin/slack-basic"
SLACK_DESKTOP_OVERRIDE="$HOME/.local/share/applications/slack_slack.desktop"

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

# 8) Fix Slack Snap: persistencia de sesion con password-store=basic
if [ -x /snap/bin/slack ]; then
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"

  cat > "$SLACK_WRAPPER_TARGET" <<'EOF'
#!/usr/bin/env bash
exec /snap/bin/slack --password-store=basic "$@"
EOF
  chmod +x "$SLACK_WRAPPER_TARGET"

  cat > "$SLACK_DESKTOP_OVERRIDE" <<EOF
[Desktop Entry]
X-SnapInstanceName=slack
Name=Slack
StartupWMClass=Slack
Comment=Slack Desktop
GenericName=Slack Client for Linux
X-SnapAppName=slack
Exec=$SLACK_WRAPPER_TARGET %U
Icon=/snap/slack/current/usr/share/pixmaps/slack.png
Type=Application
StartupNotify=true
Categories=GNOME;GTK;Network;InstantMessaging;
MimeType=x-scheme-handler/slack;
EOF

  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" || true
  fi

  echo "Fix Slack aplicado: launcher local con --password-store=basic."
  echo "Si Slack sigue en el dock, desanclalo y vuelve a anclarlo."
else
  echo "Slack Snap no esta instalado. Se omite fix de persistencia."
fi
