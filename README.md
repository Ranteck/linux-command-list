# Ubuntu post-instalación – comandos rápidos

Repositorio personal para reinstalaciones rápidas de Ubuntu: utilidades que quiero tener a mano tras formatear/instalar. Incluye comandos de instalación, funciones de mantenimiento y ejemplos de uso. Los comandos base están en `list command for terminal.sh`.

## Cómo usar este repo
1. Clona el repo en tu máquina fresca.
2. Revisa `list command for terminal.sh` y ejecuta los comandos que necesites.
3. Guarda aquí cualquier nuevo comando/nota para tenerlo listo en la próxima reinstalación.

## Herramientas incluidas

### 1) lsd (ls con colores/íconos)
- Instalar: `sudo apt install lsd` (requiere fuente Nerd Font para íconos).
- Uso: `lsd -la` para listar con detalles e íconos.

### 2) Atuin (historial mejorado)
- Instalar: `bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)`
- Registrar y sincronizar:
  - `atuin register -u <USERNAME> -e <EMAIL>`
  - `atuin import auto`
  - `atuin sync`
- Uso: `atuin search "<texto>"` (ej. `atuin search git`) o usa `Ctrl+R` si la integración está activa.

### 3) fzf (búsqueda difusa)
- Instalar: `sudo apt install fzf`
- Uso rápido:
  - Seleccionar línea de un archivo: `cat archivo.txt | fzf`
  - Buscar un archivo y abrirlo: `fzf | xargs -r ${EDITOR:-vim}`

### 4) pipx + tldr (ejemplos de comandos)
- Prep: `sudo apt update && sudo apt install python3-pip pipx && pipx ensurepath` (reabre la terminal tras ensurepath).
- Instalar tldr: `pipx install tldr`
- Uso: `tldr tar` para ver ejemplos cortos de un comando.

### 5) Funciones de mantenimiento (`bashrc aliases.sh`)
- Archivo: `bashrc aliases.sh` (cárgalo con `source "bashrc aliases.sh"`).
- `cleanup <paquete>`: desinstala de apt/snap/flatpak, limpia caché y borra configuraciones locales.
  - Ejemplo: `cleanup firefox`
- `sysupdate`: actualización y limpieza del sistema (`apt-get update/upgrade/autoremove/clean`).
  - Ejemplo: `sysupdate`

### 6) Lista APT post-formateo (`instalacion_apt_postformateo.sh`)
- Archivo: `instalacion_apt_postformateo.sh`
- Enfoque: listado de `sudo apt-get install ...` por bloques para ir instalando manualmente.
- Al finalizar, migra automáticamente `bashrc aliases.sh` a `~/.bash_aliases` (con backup) y asegura su carga en `~/.bashrc`.
- Tambien configura Wayland como preferencia a nivel usuario en `~/.dmrc` (con backup), sin tocar GDM global.
- Uso:
  - `chmod +x instalacion_apt_postformateo.sh`
  - `./instalacion_apt_postformateo.sh`
  - O copiar/pegar solo los bloques que quieras ejecutar.

### 7) Backup y restore post-formateo (`backup_formateo.sh`) - opcional
- Archivo: `backup_formateo.sh`.
- Dar permisos (si hace falta): `chmod +x backup_formateo.sh`
- Crear backup:
  - `./backup_formateo.sh backup`
- Restaurar en instalación nueva:
  - `./backup_formateo.sh restore "<ruta_del_backup>"`
- Este script guarda/restaura:
  - Lista de paquetes APT manuales
  - Lista de apps Snap y Flatpak
  - Configuración GNOME (`dconf`) y extensiones de usuario

### 8) Dependencias recomendadas para GNOME Tiling + restore
- Instalar base:
  - `sudo apt-get update`
  - `sudo apt-get install -y gnome-shell-extension-manager gnome-shell-extensions dconf-cli`

## Archivo de referencia
- `list command for terminal.sh`: contiene las instalaciones y ejemplos rápidos (edítalo para agregar más).
- `bashrc aliases.sh`: funciones reutilizables de limpieza/actualización.
- `instalacion_apt_postformateo.sh`: lista de instalaciones APT por bloques.
- `backup_formateo.sh`: backup y restore de paquetes + GNOME/extensiones.
