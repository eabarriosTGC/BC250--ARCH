#!/bin/bash

# Colores para el output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}   INSTALADOR AUTOMÁTICO AMD BC-250 - ARCH LINUX ${NC}"
echo -e "${GREEN}=================================================${NC}"
echo -e "${YELLOW}Este script compilará e instalará Kernel y Mesa parcheados.${NC}"
echo -e "${YELLOW}ADVERTENCIA: Compilar el Kernel puede tardar 1-2 horas.${NC}"
echo ""

# Verificar si se corre como root
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}Por favor, NO ejecutes este script como root (sudo).${NC}"
  echo "El script pedirá contraseña cuando sea necesario para pacman."
  exit 1
fi

# 1. Instalar dependencias base
echo -e "${GREEN}[1/5] Verificando dependencias de compilación...${NC}"
sudo pacman -S --needed --noconfirm base-devel git python

# Función para construir paquetes
build_package() {
    local pkg_dir=$1
    echo -e "${YELLOW}>>> Entrando a compilar: $pkg_dir ${NC}"
    cd "$pkg_dir" || exit
    
    # Limpiar builds previos
    rm -rf src/ pkg/ *.tar.zst
    
    # Compilar e instalar
    makepkg -si --noconfirm
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}!!! Error compilando $pkg_dir. Abortando.${NC}"
        exit 1
    fi
    cd ../..
}

# 2. Kernel LTS
echo ""
read -p "¿Deseas compilar e instalar el Kernel LTS (6.6.x) parcheado? (s/n): " install_kernel
if [[ "$install_kernel" =~ ^[Ss]$ ]]; then
    echo -e "${GREEN}[2/5] Compilando Kernel LTS BC-250...${NC}"
    build_package "pkgs/linux-lts-bc250"
    
    echo -e "${YELLOW}>>> Actualizando GRUB...${NC}"
    if [ -f /boot/grub/grub.cfg ]; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    else
        echo -e "${RED}No se detectó GRUB. Si usas systemd-boot, asegúrate de añadir la entrada del kernel manualmente.${NC}"
    fi
else
    echo "Saltando instalación del Kernel."
fi

# 3. Mesa (Drivers Gráficos)
echo ""
read -p "¿Deseas compilar e instalar MESA (Drivers de Video)? (s/n): " install_mesa
if [[ "$install_mesa" =~ ^[Ss]$ ]]; then
    echo -e "${GREEN}[3/5] Preparando instalación de Mesa...${NC}"
    
    # Remover mesa oficial para evitar conflictos durante la instalación
    echo -e "${YELLOW}>>> Removiendo 'mesa' estándar para evitar conflictos...${NC}"
    sudo pacman -Rdd --noconfirm mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon 2>/dev/null
    
    echo -e "${GREEN}>>> Compilando Mesa 64-bits...${NC}"
    build_package "pkgs/mesa-bc250"
    
    # Preguntar por lib32
    read -p "¿Necesitas librerías de 32 bits (para Steam/Juegos viejos)? (s/n): " install_lib32
    if [[ "$install_lib32" =~ ^[Ss]$ ]]; then
        echo -e "${GREEN}>>> Compilando Mesa 32-bits...${NC}"
        build_package "pkgs/lib32-mesa-bc250"
    fi
else
    echo "Saltando instalación de Mesa."
fi

# 4. Servicio de Performance (Governor)
echo ""
echo -e "${GREEN}[4/5] Instalando servicio de rendimiento (Governor Fix)...${NC}"
if [ -f "systemd/amdgpu-bc250.service" ]; then
    sudo cp systemd/amdgpu-bc250.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable --now amdgpu-bc250.service
    echo -e "${GREEN}>>> Servicio activado correctamente.${NC}"
else
    echo -e "${RED}!!! No se encontró el archivo systemd/amdgpu-bc250.service${NC}"
fi

# 5. Proteger paquetes (Pacman conf)
echo ""
read -p "¿Deseas bloquear actualizaciones de Kernel y Mesa en pacman.conf para evitar roturas futuras? (Recomendado) (s/n): " protect_pkgs
if [[ "$protect_pkgs" =~ ^[Ss]$ ]]; then
    echo -e "${GREEN}[5/5] Modificando /etc/pacman.conf...${NC}"
    
    # Definir paquetes a ignorar
    IGNORE_PKGS="linux-lts-amd-bc250 linux-lts-amd-bc250-headers mesa-amd-bc250 vulkan-radeon-amd-bc250 lib32-mesa-amd-bc250 lib32-vulkan-radeon-amd-bc250"
    
    # Chequear si ya existe la línea IgnorePkg
    if grep -q "^IgnorePkg" /etc/pacman.conf; then
        echo -e "${YELLOW}Ya existe una línea IgnorePkg. Por favor edita /etc/pacman.conf manualmente y añade:${NC}"
        echo "$IGNORE_PKGS"
    else
        # Si está comentada, la descomentamos y añadimos
        sudo sed -i "s/^#IgnorePkg/IgnorePkg/" /etc/pacman.conf
        sudo sed -i "/^IgnorePkg/ s/$/ $IGNORE_PKGS/" /etc/pacman.conf
        echo -e "${GREEN}>>> Paquetes añadidos a IgnorePkg.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}   INSTALACIÓN FINALIZADA   ${NC}"
echo -e "${GREEN}=================================================${NC}"
echo "Por favor, reinicia tu sistema y selecciona el Kernel 'linux-lts-amd-bc250' en el arranque."
