# Ubuntu post-instalación – comandos rápidos

Lista corta de utilidades que quiero tener a mano tras formatear/instalar Ubuntu. Los comandos base están en `list command for terminal.sh`.

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

### 5) Funciones de mantenimiento (`comandos utiles.sh`)
- Archivo: `comandos utiles.sh` (cárgalo con `source "comandos utiles.sh"`).
- `cleanup <paquete>`: desinstala de apt/snap/flatpak, limpia caché y borra configuraciones locales.
  - Ejemplo: `cleanup firefox`
- `sysupdate`: cadena rápida para `apt update && apt upgrade && apt install -y && apt autoremove`.
  - Ejemplo: `sysupdate`

## Archivo de referencia
- `list command for terminal.sh`: contiene las instalaciones y ejemplos rápidos (edítalo para agregar más).
- `comandos utiles.sh`: funciones reutilizables de limpieza/actualización.
