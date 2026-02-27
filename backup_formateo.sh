#!/usr/bin/env bash

# Backup/restore de personalizacion para post-formateo.
# Uso:
#   ./backup_formateo.sh backup [directorio_backup]
#   ./backup_formateo.sh restore <directorio_backup> [--with-core-tools]

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BACKUP_BASE="$SCRIPT_DIR/backups"

usage() {
  cat <<'EOF'
Uso:
  backup_formateo.sh backup [directorio_backup]
  backup_formateo.sh restore <directorio_backup> [--with-core-tools]

Comandos:
  backup   Guarda configuraciones GNOME/extensiones y archivos de usuario relevantes.
  restore  Restaura esas configuraciones en una instalacion nueva.

Opciones restore:
  --with-core-tools  Instala dconf-cli + herramientas base de extensiones GNOME.
EOF
}

run_with_timeout() {
  local seconds="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
  else
    "$@"
  fi
}

backup_mode() {
  local backup_dir="${1:-$DEFAULT_BACKUP_BASE/$(date +%Y%m%d_%H%M%S)}"
  local files_dir="$backup_dir/files"

  mkdir -p "$backup_dir" "$files_dir" || return 1
  echo "Guardando backup en: $backup_dir"

  date -Iseconds > "$backup_dir/created_at.txt"
  hostnamectl --static > "$backup_dir/hostname.txt" 2>/dev/null || true
  uname -a > "$backup_dir/uname.txt" 2>/dev/null || true

  # Estado de paquetes (referencia)
  apt-mark showmanual | sort > "$backup_dir/apt-manual.txt" 2>/dev/null || true

  if command -v snap >/dev/null 2>&1; then
    run_with_timeout 10 snap list > "$backup_dir/snap-list.txt" 2>/dev/null || true
  fi
  if command -v flatpak >/dev/null 2>&1; then
    flatpak list --app --columns=application > "$backup_dir/flatpak-apps.txt" 2>/dev/null || true
  fi

  # GNOME
  gnome-shell --version > "$backup_dir/gnome-shell-version.txt" 2>/dev/null || true
  if command -v gnome-extensions >/dev/null 2>&1; then
    gnome-extensions list > "$backup_dir/gnome-extensions-all.txt" 2>/dev/null || true
    gnome-extensions list --enabled > "$backup_dir/gnome-extensions-enabled.txt" 2>/dev/null || true
  fi

  if command -v dconf >/dev/null 2>&1; then
    dconf dump /org/gnome/ > "$backup_dir/dconf-org-gnome.ini" 2>/dev/null || true
    dconf dump /org/gnome/shell/extensions/ > "$backup_dir/dconf-gnome-extensions.ini" 2>/dev/null || true
  fi

  if [ -d "$HOME/.local/share/gnome-shell/extensions" ]; then
    tar -czf "$backup_dir/gnome-shell-extensions-user.tar.gz" \
      -C "$HOME/.local/share/gnome-shell" extensions
  fi

  # Archivos de usuario relevantes para tu setup
  [ -f "$HOME/.dmrc" ] && cp "$HOME/.dmrc" "$files_dir/.dmrc"
  [ -f "$HOME/.bash_aliases" ] && cp "$HOME/.bash_aliases" "$files_dir/.bash_aliases"
  [ -f "$HOME/.local/bin/slack-basic" ] && cp "$HOME/.local/bin/slack-basic" "$files_dir/slack-basic"
  if [ -f "$HOME/.local/share/applications/slack_slack.desktop" ]; then
    cp "$HOME/.local/share/applications/slack_slack.desktop" "$files_dir/slack_slack.desktop"
  fi

  echo "Backup finalizado."
  echo "Ruta: $backup_dir"
}

install_core_tools() {
  sudo apt-get update
  sudo apt-get install -y \
    dconf-cli \
    gnome-shell-extension-manager \
    gnome-shell-extensions
}

restore_mode() {
  local backup_dir="${1:-}"
  local with_core_tools="${2:-}"
  local files_dir="$backup_dir/files"

  if [ -z "$backup_dir" ] || [ ! -d "$backup_dir" ]; then
    echo "Directorio de backup invalido: $backup_dir"
    return 1
  fi

  echo "Restaurando desde: $backup_dir"

  if [ "$with_core_tools" = "--with-core-tools" ]; then
    install_core_tools || return 1
  fi

  mkdir -p "$HOME/.local/share/gnome-shell" "$HOME/.local/bin" "$HOME/.local/share/applications"

  if [ -f "$backup_dir/gnome-shell-extensions-user.tar.gz" ]; then
    tar -xzf "$backup_dir/gnome-shell-extensions-user.tar.gz" -C "$HOME/.local/share/gnome-shell"
  fi

  if command -v dconf >/dev/null 2>&1; then
    [ -f "$backup_dir/dconf-org-gnome.ini" ] && dconf load /org/gnome/ < "$backup_dir/dconf-org-gnome.ini"
    [ -f "$backup_dir/dconf-gnome-extensions.ini" ] && dconf load /org/gnome/shell/extensions/ < "$backup_dir/dconf-gnome-extensions.ini"
  else
    echo "dconf no instalado. Se omite restauracion dconf."
  fi

  if command -v gnome-extensions >/dev/null 2>&1 && [ -f "$backup_dir/gnome-extensions-enabled.txt" ]; then
    while IFS= read -r ext; do
      [ -n "$ext" ] || continue
      gnome-extensions enable "$ext" >/dev/null 2>&1 || true
    done < "$backup_dir/gnome-extensions-enabled.txt"
  fi

  # Restaurar archivos de usuario
  [ -f "$files_dir/.dmrc" ] && cp "$files_dir/.dmrc" "$HOME/.dmrc"
  [ -f "$files_dir/.bash_aliases" ] && cp "$files_dir/.bash_aliases" "$HOME/.bash_aliases"
  [ -f "$files_dir/slack-basic" ] && cp "$files_dir/slack-basic" "$HOME/.local/bin/slack-basic" && chmod +x "$HOME/.local/bin/slack-basic"
  if [ -f "$files_dir/slack_slack.desktop" ]; then
    cp "$files_dir/slack_slack.desktop" "$HOME/.local/share/applications/slack_slack.desktop"
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
  fi

  echo "Restore finalizado."
  echo "Recomendado: cerrar sesion y volver a entrar."
}

main() {
  local action="${1:-}"
  case "$action" in
    backup)
      shift
      backup_mode "${1:-}"
      ;;
    restore)
      shift
      restore_mode "${1:-}" "${2:-}"
      ;;
    -h|--help|"")
      usage
      ;;
    *)
      echo "Accion no valida: $action"
      usage
      return 1
      ;;
  esac
}

main "$@"
