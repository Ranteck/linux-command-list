#!/usr/bin/env bash

# Backup/restore para no perder configuraciones al formatear Ubuntu.
# Uso:
#   ./backup_formateo.sh backup [directorio_backup]
#   ./backup_formateo.sh restore <directorio_backup>

set -u

DEFAULT_BASE_DIR="$HOME/Documentos/Proyectos Personales/linux-command-list/backups"

usage() {
    cat <<'EOF'
Uso:
  backup_formateo.sh backup [directorio_backup]
  backup_formateo.sh restore <directorio_backup>

Comandos:
  backup   Guarda listas de paquetes y configuraciones GNOME/extensiones.
  restore  Restaura desde un backup previamente creado.
EOF
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Falta comando requerido: $1"
        return 1
    }
}

backup_mode() {
    local backup_dir="${1:-$DEFAULT_BASE_DIR/$(date +%Y%m%d_%H%M%S)}"
    mkdir -p "$backup_dir" || return 1

    echo "Guardando backup en: $backup_dir"

    # Paquetes
    require_cmd apt-mark || return 1
    apt-mark showmanual | sort > "$backup_dir/apt-manual.txt"

    if command -v snap >/dev/null 2>&1; then
        snap list | awk 'NR>1{print $1}' > "$backup_dir/snap-list.txt"
    fi

    if command -v flatpak >/dev/null 2>&1; then
        flatpak list --app --columns=application > "$backup_dir/flatpak-apps.txt"
    fi

    # Info de entorno GNOME
    gnome-shell --version > "$backup_dir/gnome-shell-version.txt" 2>/dev/null || true

    if command -v gnome-extensions >/dev/null 2>&1; then
        gnome-extensions list > "$backup_dir/gnome-extensions-all.txt" || true
        gnome-extensions list --enabled > "$backup_dir/gnome-extensions-enabled.txt" || true
    fi

    # Config GNOME y extensiones (atajos, tiling, etc.)
    if command -v dconf >/dev/null 2>&1; then
        dconf dump /org/gnome/ > "$backup_dir/dconf-org-gnome.ini" || true
        dconf dump /org/gnome/shell/extensions/ > "$backup_dir/dconf-gnome-extensions.ini" || true
    fi

    # Extensiones instaladas en usuario
    if [ -d "$HOME/.local/share/gnome-shell/extensions" ]; then
        tar -czf "$backup_dir/gnome-shell-extensions-user.tar.gz" \
            -C "$HOME/.local/share/gnome-shell" extensions
    fi

    echo "Backup finalizado."
    echo "Ruta: $backup_dir"
}

install_core_tools() {
    sudo apt-get update
    sudo apt-get install -y \
        gnome-shell-extension-manager \
        gnome-shell-extensions \
        dconf-cli
}

restore_apt_manual() {
    local file="$1"
    [ -f "$file" ] || return 0

    echo "Restaurando paquetes APT manuales (esto puede tardar)..."
    while IFS= read -r pkg; do
        [ -n "$pkg" ] || continue
        sudo apt-get install -y "$pkg" || echo "Aviso: no se pudo instalar '$pkg'"
    done < "$file"
}

restore_snap() {
    local file="$1"
    [ -f "$file" ] || return 0
    command -v snap >/dev/null 2>&1 || return 0

    echo "Restaurando snaps..."
    while IFS= read -r pkg; do
        [ -n "$pkg" ] || continue
        sudo snap install "$pkg" || echo "Aviso: no se pudo instalar snap '$pkg'"
    done < "$file"
}

restore_flatpak() {
    local file="$1"
    [ -f "$file" ] || return 0
    command -v flatpak >/dev/null 2>&1 || return 0

    echo "Restaurando flatpaks..."
    while IFS= read -r app; do
        [ -n "$app" ] || continue
        flatpak install -y flathub "$app" || echo "Aviso: no se pudo instalar flatpak '$app'"
    done < "$file"
}

restore_mode() {
    local backup_dir="$1"
    if [ -z "${backup_dir:-}" ]; then
        echo "Debes indicar el directorio de backup."
        return 1
    fi
    if [ ! -d "$backup_dir" ]; then
        echo "No existe directorio: $backup_dir"
        return 1
    fi

    echo "Restaurando desde: $backup_dir"
    install_core_tools || return 1

    restore_apt_manual "$backup_dir/apt-manual.txt"
    restore_snap "$backup_dir/snap-list.txt"
    restore_flatpak "$backup_dir/flatpak-apps.txt"

    if [ -f "$backup_dir/gnome-shell-extensions-user.tar.gz" ]; then
        mkdir -p "$HOME/.local/share/gnome-shell"
        tar -xzf "$backup_dir/gnome-shell-extensions-user.tar.gz" \
            -C "$HOME/.local/share/gnome-shell"
    fi

    if command -v dconf >/dev/null 2>&1; then
        if [ -f "$backup_dir/dconf-org-gnome.ini" ]; then
            dconf load /org/gnome/ < "$backup_dir/dconf-org-gnome.ini"
        fi
        if [ -f "$backup_dir/dconf-gnome-extensions.ini" ]; then
            dconf load /org/gnome/shell/extensions/ < "$backup_dir/dconf-gnome-extensions.ini"
        fi
    fi

    if command -v gnome-extensions >/dev/null 2>&1 && [ -f "$backup_dir/gnome-extensions-enabled.txt" ]; then
        while IFS= read -r ext; do
            [ -n "$ext" ] || continue
            gnome-extensions enable "$ext" || true
        done < "$backup_dir/gnome-extensions-enabled.txt"
    fi

    echo "Restore finalizado."
    echo "Recomendado: cerrar sesion y volver a entrar para aplicar todo GNOME."
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
            restore_mode "${1:-}"
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
