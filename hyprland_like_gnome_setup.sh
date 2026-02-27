#!/usr/bin/env bash

# GNOME "Hyprland-like" setup without replacing GNOME.
# - Installs compatible extensions for current GNOME major version.
# - Enables them.
# - Applies a practical preset (gaps, blur, rounded corners, cleaner panel).

set -euo pipefail

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta comando requerido: $1"
    exit 1
  }
}

need_cmd gnome-shell
need_cmd gnome-extensions
need_cmd gsettings
need_cmd curl
need_cmd unzip

SHELL_MAJOR="$(gnome-shell --version | sed -E 's/.* ([0-9]+)\..*/\1/')"

if ! [[ "$SHELL_MAJOR" =~ ^[0-9]+$ ]]; then
  echo "No pude detectar la version de GNOME Shell."
  exit 1
fi

BASE_URL="https://extensions.gnome.org"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

install_extension_from_store() {
  local ext_id="$1"
  local ext_uuid="$2"
  local ext_name="$3"
  local json download_path zip_file

  echo "Instalando: $ext_name ($ext_uuid) para GNOME $SHELL_MAJOR..."
  json="$(curl -fsSL "$BASE_URL/extension-info/?pk=$ext_id&shell_version=$SHELL_MAJOR")"
  download_path="$(echo "$json" | tr -d '\n' | sed -n 's/.*"download_url":[[:space:]]*"\([^"]*\)".*/\1/p')"

  if [ -z "$download_path" ]; then
    echo "No hay build compatible en extensions.gnome.org para $ext_name (GNOME $SHELL_MAJOR)."
    return 1
  fi

  zip_file="$TMP_DIR/${ext_uuid}.zip"
  curl -fsSL "$BASE_URL$download_path" -o "$zip_file"
  gnome-extensions install -f "$zip_file"
  gnome-extensions enable "$ext_uuid" || true
}

# Core visual/tiling extensions
install_extension_from_store 7065 "tilingshell@ferrarodomenico.com" "Tiling Shell"
install_extension_from_store 3193 "blur-my-shell@aunetx" "Blur my Shell"
install_extension_from_store 3843 "just-perfection-desktop@just-perfection" "Just Perfection"

# Rounded corners extension changed UUID for newer GNOME
ROUNDED_UUID="rounded-window-corners@yilozt"
ROUNDED_ID="5237"
if [ "$SHELL_MAJOR" -ge 46 ]; then
  ROUNDED_UUID="rounded-window-corners@fxgn"
  ROUNDED_ID="7048"
fi
install_extension_from_store "$ROUNDED_ID" "$ROUNDED_UUID" "Rounded Window Corners"

# Ensure all are enabled
gnome-extensions enable "tilingshell@ferrarodomenico.com" || true
gnome-extensions enable "blur-my-shell@aunetx" || true
gnome-extensions enable "just-perfection-desktop@just-perfection" || true
gnome-extensions enable "$ROUNDED_UUID" || true

# Global GNOME base tweaks
if gsettings list-keys org.gnome.desktop.interface | grep -Fxq enable-hot-corners; then
  gsettings set org.gnome.desktop.interface enable-hot-corners false
fi
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.mutter dynamic-workspaces true

# Ubuntu Dock: mantenerlo abajo para conservar indicador inferior.
if gsettings list-schemas | grep -Fxq org.gnome.shell.extensions.dash-to-dock; then
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
fi

# Extension-specific settings
TS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/tilingshell@ferrarodomenico.com/schemas"
BMS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas"
JP_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/just-perfection-desktop@just-perfection/schemas"
RWC_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/$ROUNDED_UUID/schemas"

# Tiling Shell
gsettings --schemadir "$TS_SCHEMA_DIR" set org.gnome.shell.extensions.tilingshell enable-autotiling true
gsettings --schemadir "$TS_SCHEMA_DIR" set org.gnome.shell.extensions.tilingshell inner-gaps 14
gsettings --schemadir "$TS_SCHEMA_DIR" set org.gnome.shell.extensions.tilingshell outer-gaps 10
gsettings --schemadir "$TS_SCHEMA_DIR" set org.gnome.shell.extensions.tilingshell edge-tiling-mode 'adaptive'
gsettings --schemadir "$TS_SCHEMA_DIR" set org.gnome.shell.extensions.tilingshell enable-window-border true
gsettings --schemadir "$TS_SCHEMA_DIR" set org.gnome.shell.extensions.tilingshell window-use-custom-border-color true
gsettings --schemadir "$TS_SCHEMA_DIR" set org.gnome.shell.extensions.tilingshell window-border-color '#7aa2f7'
gsettings --schemadir "$TS_SCHEMA_DIR" set org.gnome.shell.extensions.tilingshell window-border-width 2
gsettings --schemadir "$TS_SCHEMA_DIR" set org.gnome.shell.extensions.tilingshell enable-blur-snap-assistant true

# Blur my Shell
gsettings --schemadir "$BMS_SCHEMA_DIR" set org.gnome.shell.extensions.blur-my-shell sigma 40
gsettings --schemadir "$BMS_SCHEMA_DIR" set org.gnome.shell.extensions.blur-my-shell brightness 0.55
gsettings --schemadir "$BMS_SCHEMA_DIR" set org.gnome.shell.extensions.blur-my-shell.panel blur true
gsettings --schemadir "$BMS_SCHEMA_DIR" set org.gnome.shell.extensions.blur-my-shell.panel override-background true
gsettings --schemadir "$BMS_SCHEMA_DIR" set org.gnome.shell.extensions.blur-my-shell.panel unblur-in-overview false
gsettings --schemadir "$BMS_SCHEMA_DIR" set org.gnome.shell.extensions.blur-my-shell.panel static-blur true
gsettings --schemadir "$BMS_SCHEMA_DIR" set org.gnome.shell.extensions.blur-my-shell.panel style-panel 0

# Just Perfection
gsettings --schemadir "$JP_SCHEMA_DIR" set org.gnome.shell.extensions.just-perfection activities-button false
gsettings --schemadir "$JP_SCHEMA_DIR" set org.gnome.shell.extensions.just-perfection app-menu false
gsettings --schemadir "$JP_SCHEMA_DIR" set org.gnome.shell.extensions.just-perfection ripple-box false
gsettings --schemadir "$JP_SCHEMA_DIR" set org.gnome.shell.extensions.just-perfection startup-status 0
gsettings --schemadir "$JP_SCHEMA_DIR" set org.gnome.shell.extensions.just-perfection workspace-wrap-around true
gsettings --schemadir "$JP_SCHEMA_DIR" set org.gnome.shell.extensions.just-perfection panel-size 32
gsettings --schemadir "$JP_SCHEMA_DIR" set org.gnome.shell.extensions.just-perfection animation 2

# Rounded Window Corners
gsettings --schemadir "$RWC_SCHEMA_DIR" set org.gnome.shell.extensions.rounded-window-corners skip-libadwaita-app false
gsettings --schemadir "$RWC_SCHEMA_DIR" set org.gnome.shell.extensions.rounded-window-corners tweak-kitty-terminal true

echo ""
echo "Preset aplicado."
echo "Extensiones activas:"
gsettings get org.gnome.shell enabled-extensions
echo "Si no ves todos los cambios, cierra sesion y vuelve a entrar."
