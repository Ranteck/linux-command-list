# =========================
# cleanup: desinstala paquete (apt/snap/flatpak) + limpia + actualiza
# Uso: cleanup <nombre_paquete> [--no-update] [--no-upgrade] [--keep-local-data] [--dry-run]
# =========================
_cleanup_validate_pkg_name() {
    local pkg="$1"
    if [ -z "$pkg" ]; then
        echo "Uso: cleanup <nombre_paquete> [--no-update] [--no-upgrade] [--keep-local-data] [--dry-run]"
        return 1
    fi

    case "$pkg" in
        .|..|*/*)
            echo "Nombre de paquete invalido: $pkg"
            return 1
            ;;
    esac

    if ! [[ "$pkg" =~ ^[a-zA-Z0-9._:+-]+$ ]]; then
        echo "Nombre de paquete invalido: $pkg"
        return 1
    fi
}

_cleanup_cmd_with_timeout() {
    local seconds="$1"
    shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" "$@"
    else
        "$@"
    fi
}

_cleanup_snap_installed() {
    command -v snap >/dev/null 2>&1 || return 1
    _cleanup_cmd_with_timeout 8 snap list "$1" >/dev/null 2>&1
}

_cleanup_flatpak_installed() {
    command -v flatpak >/dev/null 2>&1 || return 1
    _cleanup_cmd_with_timeout 8 flatpak info --app "$1" >/dev/null 2>&1
}

cleanup() {
    local pkg="$1"
    shift || true

    local do_update=1
    local do_upgrade=1
    local remove_local_data=1
    local dry_run=0

    while [ $# -gt 0 ]; do
        case "$1" in
            --no-update) do_update=0 ;;
            --no-upgrade) do_upgrade=0 ;;
            --keep-local-data) remove_local_data=0 ;;
            --dry-run) dry_run=1 ;;
            -h|--help)
                _cleanup_validate_pkg_name ""
                return 0
                ;;
            *)
                echo "Opcion no reconocida: $1"
                return 1
                ;;
        esac
        shift
    done

    _cleanup_validate_pkg_name "$pkg" || return 1

    local removed_any=0
    local status=0

    echo "Iniciando limpieza de: $pkg"

    # 1) APT (.deb)
    if dpkg-query -W -f='${db:Status-Status}\n' "$pkg" 2>/dev/null | grep -Fxq "installed"; then
        if [ "$dry_run" -eq 1 ]; then
            echo "[dry-run] sudo apt-get purge -y \"$pkg\""
            removed_any=1
        elif sudo apt-get purge -y "$pkg"; then
            removed_any=1
        else
            status=1
        fi
    fi

    # 2) SNAP
    if _cleanup_snap_installed "$pkg"; then
        if [ "$dry_run" -eq 1 ]; then
            echo "[dry-run] sudo snap remove --purge \"$pkg\""
            removed_any=1
        elif sudo snap remove --purge "$pkg"; then
            removed_any=1
        else
            status=1
        fi
    fi

    # 3) FLATPAK
    if _cleanup_flatpak_installed "$pkg"; then
        if [ "$dry_run" -eq 1 ]; then
            echo "[dry-run] flatpak uninstall -y --delete-data \"$pkg\""
            removed_any=1
        elif flatpak uninstall -y --delete-data "$pkg"; then
            removed_any=1
        else
            status=1
        fi
    fi

    if [ "$removed_any" -eq 0 ]; then
        echo "No se encontro '$pkg' instalado en apt, snap o flatpak."
    fi

    if [ "$dry_run" -eq 1 ]; then
        echo "[dry-run] sudo apt-get autoremove --purge -y"
        echo "[dry-run] sudo apt-get clean"
        if [ "$do_update" -eq 1 ]; then
            echo "[dry-run] sudo apt-get update"
        fi
        if [ "$do_upgrade" -eq 1 ]; then
            echo "[dry-run] sudo apt-get upgrade -y"
        fi
    else
        sudo apt-get autoremove --purge -y || status=1
        sudo apt-get clean || status=1
        if [ "$do_update" -eq 1 ]; then
            sudo apt-get update || status=1
        fi
        if [ "$do_upgrade" -eq 1 ]; then
            sudo apt-get upgrade -y || status=1
        fi
    fi

    if [ "$remove_local_data" -eq 1 ]; then
        local base target
        for base in "$HOME/.config" "$HOME/.local/share" "$HOME/.cache"; do
            target="$base/$pkg"
            if [ -e "$target" ]; then
                if [ "$dry_run" -eq 1 ]; then
                    echo "[dry-run] rm -rf -- \"$target\""
                else
                    rm -rf -- "$target" || status=1
                fi
            fi
        done
    fi

    if [ "$status" -eq 0 ]; then
        echo "Limpieza finalizada sin errores."
    else
        echo "Limpieza finalizada con errores. Revisa la salida."
    fi

    return "$status"
}

# =========================
# sysupdate: actualiza y limpia el sistema
# Uso: sysupdate
# =========================
sysupdate() {
    local status=0

    sudo apt-get update || status=1
    sudo apt-get upgrade -y || status=1
    sudo apt-get autoremove --purge -y || status=1
    sudo apt-get clean || status=1

    if [ "$status" -eq 0 ]; then
        echo "Actualizacion del sistema finalizada."
    else
        echo "Actualizacion finalizada con errores. Revisa la salida."
    fi

    return "$status"
}
