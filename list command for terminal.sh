# ======================
# LSD — ls con iconos
# ======================
sudo apt install lsd  # requiere Nerd Font para íconos
# Uso: listar con detalles e íconos
lsd -la

# ======================
# Atuin — historial mejorado
# ======================
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
atuin register -u <USERNAME> -e <EMAIL>
atuin import auto
atuin sync
# Uso: búsqueda de historial (reemplaza Ctrl+R)
atuin search "<texto>"  # ej: atuin search git
# o usa Ctrl+R si está integrado

# ======================
# fzf — búsqueda difusa
# ======================
sudo apt install fzf
# Uso: elegir una línea de un archivo
cat archivo.txt | fzf
# Uso: buscar un archivo y abrirlo
fzf | xargs -r ${EDITOR:-vim}

# ======================
# pipx + tldr — ejemplos cortos
# ======================
# Primero instala pip/pipx si no los tienes
sudo apt update
sudo apt install python3-pip
sudo apt install pipx
pipx ensurepath

pipx install tldr
# Uso: ejemplos rápidos de un comando
tldr tar


