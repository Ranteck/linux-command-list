# =========================
# cleanup: desinstala paquete (apt/snap/flatpak) + limpia + actualiza
# Uso: cleanup <nombre_paquete>
# =========================
cleanup() {
    local pkg="$1"
    if [ -z "$pkg" ]; then
        echo "⚠️  Uso: cleanup <nombre_paquete>"
        return 1
    fi

    echo "🧹 Desinstalando $pkg y limpiando el sistema..."

    removed=0

    # 1) APT (.deb)
    if dpkg -l | awk '{print $2}' | grep -Fxq "$pkg"; then
        sudo apt purge -y "$pkg" && removed=1
    fi

    # 2) SNAP
    if [ $removed -eq 0 ] && command -v snap >/dev/null 2>&1; then
        if snap list | awk 'NR>1{print $1}' | grep -Fxq "$pkg"; then
            # --purge intenta borrar también datos comunes del snap
            sudo snap remove --purge "$pkg" && removed=1
        fi
    fi

    # 3) FLATPAK
    if [ $removed -eq 0 ] && command -v flatpak >/dev/null 2>&1; then
        if flatpak list --app | awk '{print $1}' | grep -Fxq "$pkg"; then
            flatpak uninstall -y --delete-data "$pkg" && removed=1
        fi
    fi

    if [ $removed -eq 0 ]; then
        echo "❌ No se encontró '$pkg' en APT, Snap ni Flatpak. Continuo con limpieza general…"
    fi

    # Limpieza y actualización, como en tu cadena original
    sudo apt autoremove -y && \
    sudo apt clean && \
    sudo apt update -y && \
    sudo apt upgrade -y

    # Borrar configuraciones locales si existen (fallback para apps que dejan rastro)
    rm -rf ~/.config/"$pkg" ~/.local/share/"$pkg"

    echo "✅ Limpieza completa de $pkg finalizada."
}

# =========================
# sysupdate: tu cadena tal cual (update + upgrade + install vacío + autoremove)
# Uso: sysupdate
# =========================
sysupdate() {
    sudo apt update -y && \
    sudo apt upgrade -y && \
    sudo apt install -y && \
    sudo apt autoremove -y
}