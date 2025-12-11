#!/bin/bash

# =================================================================================
#  AMD BC-250: ULTIMATE ARCH/MANJARO SETUP (ALL-IN-ONE)
#  Incluye: Kernel LTS Fix, Mesa Parcheado y Rust Governor
# =================================================================================

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}   AMD BC-250: SETUP AUTOMATIZADO DEFINITIVO     ${NC}"
echo -e "${GREEN}=================================================${NC}"
echo -e "${YELLOW}Este script configurará tu sistema Arch/Manjaro completamente.${NC}"
echo -e "${BLUE}Pasos incluidos:${NC}"
echo " 1. Compilación de Kernel LTS (Estabilidad)"
echo " 2. Compilación de Mesa (Gráficos/Vulkan)"
echo " 3. Instalación de Governor en Rust (Rendimiento/Energía)"
echo " 4. Protección contra actualizaciones automáticas"
echo ""

# --- 0. COMPROBACIÓN DE SEGURIDAD ---
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}ERROR: Por favor, NO ejecutes este script como root (sudo).${NC}" 
   echo "El script pedirá contraseña cuando sea necesario para pacman/systemctl."
   exit 1
fi

# --- 1. DEPENDENCIAS GENERALES ---
echo -e "${GREEN}[1/5] Verificando e instalando dependencias base...${NC}"
# Incluimos 'rust' y 'gcc' aquí para el governor
sudo pacman -S --needed --noconfirm base-devel git python rust gcc

# Función auxiliar para compilar paquetes
build_package() {
    local pkg_dir=$1
    local pkg_name=$2
    
    if [ ! -d "$pkg_dir" ]; then
        echo -e "${RED}Error: No se encuentra la carpeta $pkg_dir${NC}"
        return 1
    fi

    echo -e "${YELLOW}>>> Entrando a compilar $pkg_name...${NC}"
    cd "$pkg_dir" || exit
    
    # Limpiar builds previos
    rm -rf src/ pkg/ *.tar.zst *.tar.xz
    
    # Compilar e instalar
    makepkg -si --noconfirm
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}!!! Error compilando $pkg_name. Revisa el log.${NC}"
        exit 1
    fi
    cd ../..
}

# --- 2. KERNEL LTS (6.6.x) ---
echo ""
echo -e "${BLUE}--- SECCIÓN KERNEL ---${NC}"
read -p "¿Deseas compilar e instalar el Kernel LTS 6.6.x Parcheado? (Recomendado) (s/n): " k_opt
if [[ "$k_opt" =~ ^[Ss]$ ]]; then
    echo -e "${GREEN}[2/5] Compilando Kernel LTS BC-250...${NC}"
    echo -e "${YELLOW}Nota: Esto puede tardar entre 20 min y 2 horas según tu CPU.${NC}"
    build_package "pkgs/linux-lts-bc250" "Linux Kernel LTS"
    
    # Actualizar GRUB si existe
    if [ -f /boot/grub/grub.cfg ]; then
        echo "Actualizando configuración de GRUB..."
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
else
    echo "Saltando instalación del Kernel."
fi

# --- 3. MESA (DRIVERS GRÁFICOS) ---
echo ""
echo -e "${BLUE}--- SECCIÓN GRÁFICOS (MESA) ---${NC}"
read -p "¿Deseas compilar e instalar Mesa Parcheado (Aceleración 3D/Vulkan)? (s/n): " m_opt
if [[ "$m_opt" =~ ^[Ss]$ ]]; then
    echo -e "${GREEN}[3/5] Preparando instalación de Mesa...${NC}"
    
    # Remover mesa oficial
    echo -e "${YELLOW}>>> Removiendo drivers conflictivos (mesa, vulkan-radeon)...${NC}"
    sudo pacman -Rdd --noconfirm mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon 2>/dev/null
    
    echo -e "${GREEN}>>> Compilando Mesa 64-bits...${NC}"
    build_package "pkgs/mesa-bc250" "Mesa 3D (64-bit)"
    
    read -p "¿Necesitas librerías de 32 bits (Steam/Wine)? (s/n): " m32_opt
    if [[ "$m32_opt" =~ ^[Ss]$ ]]; then
        echo -e "${GREEN}>>> Compilando Mesa 32-bits...${NC}"
        build_package "pkgs/lib32-mesa-bc250" "Mesa 3D (32-bit)"
    fi
else
    echo "Saltando instalación de Mesa."
fi

# --- 4. GOVERNOR (RUST EDITION INTEGRADO) ---
echo ""
echo -e "${BLUE}--- SECCIÓN RENDIMIENTO (GOVERNOR) ---${NC}"
read -p "¿Instalar el Cyan Skillfish Governor (Rust)? (Corrige energía y rendimiento) (s/n): " g_opt
if [[ "$g_opt" =~ ^[Ss]$ ]]; then
    echo -e "${GREEN}[4/5] Instalando Governor...${NC}"
    
    # 4.1 Limpieza
    if systemctl is-active --quiet oberon.service; then
        sudo systemctl stop oberon.service
        sudo systemctl disable oberon.service
        sudo rm -f /etc/systemd/system/oberon.service
    fi
    
    # 4.2 Clonar y Compilar
    echo -e "${YELLOW}>>> Clonando y compilando desde GitHub (Magnap)...${NC}"
    rm -rf cyan-skillfish-governor-build
    if git clone https://github.com/Magnap/cyan-skillfish-governor.git cyan-skillfish-governor-build; then
        cd cyan-skillfish-governor-build
        cargo build --release
        
        # 4.3 Instalar Binario
        echo "Instalando binario..."
        sudo cp target/release/cyan-skillfish-governor /usr/local/bin/
        sudo chmod +x /usr/local/bin/cyan-skillfish-governor
        sudo mkdir -p /etc/cyan-skillfish-governor/
        cd ..
        rm -rf cyan-skillfish-governor-build
    else
        echo -e "${RED}Error descargando el governor. Saltando paso.${NC}"
    fi
    
    # 4.4 Crear Servicio Systemd
    echo -e "${YELLOW}>>> Creando servicio Systemd...${NC}"
    sudo tee /etc/systemd/system/cyan-skillfish-governor.service > /dev/null <<EOT
[Unit]
Description=Cyan Skillfish Governor for AMD GPUs (Rust)
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/cyan-skillfish-governor
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOT
    
    # 4.5 Configurar Kernel Parameters y Environment
    echo -e "${YELLOW}>>> Configurando parámetros del sistema...${NC}"
    
    # Environment var
    if ! grep -q "RADV_DEBUG=nocompute" /etc/environment; then
        echo 'RADV_DEBUG=nocompute' | sudo tee -a /etc/environment
    fi
    
    # Modprobe options
    echo "options amdgpu sg_display=0" | sudo tee /etc/modprobe.d/amdgpu-bc250.conf > /dev/null
    echo "options nct6683 force=true" | sudo tee /etc/modprobe.d/nct6683-bc250.conf > /dev/null
    
    # 4.6 Configurar Bootloader (GRUB)
    PARAM="amdgpu.ppfeaturemask=0xffffffff"
    if [ -f /etc/default/grub ]; then
        if ! grep -q "$PARAM" /etc/default/grub; then
            echo "Añadiendo ppfeaturemask a GRUB..."
            sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$PARAM /" /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg
        fi
    else
        echo -e "${RED}AVISO: No se detectó GRUB. Si usas systemd-boot, añade '$PARAM' manualmente a tu kernel.${NC}"
        read -p "Presiona Enter para continuar..."
    fi
    
    # Habilitar servicio
    sudo systemctl daemon-reload
    sudo systemctl enable --now cyan-skillfish-governor.service
    echo "Governor instalado y activado."
else
    echo "Saltando instalación del Governor."
fi

# --- 5. BLOQUEO DE ACTUALIZACIONES ---
echo ""
echo -e "${BLUE}--- SECCIÓN PROTECCIÓN (PACMAN) ---${NC}"
read -p "¿Bloquear actualizaciones de estos paquetes en pacman.conf? (Muy Recomendado) (s/n): " l_opt
if [[ "$l_opt" =~ ^[Ss]$ ]]; then
    echo -e "${GREEN}[5/5] Modificando /etc/pacman.conf...${NC}"
    PKG_LIST="linux-lts-amd-bc250 mesa-amd-bc250 vulkan-radeon-amd-bc250 lib32-mesa-amd-bc250 lib32-vulkan-radeon-amd-bc250"
    
    if ! grep -q "linux-lts-amd-bc250" /etc/pacman.conf; then
        # Descomentar IgnorePkg si está comentado
        sudo sed -i "s/^#IgnorePkg/IgnorePkg/" /etc/pacman.conf
        # Añadir nuestros paquetes
        sudo sed -i "/^IgnorePkg/ s/$/ $PKG_LIST/" /etc/pacman.conf
        echo "Paquetes bloqueados correctamente."
    else
        echo "Parece que ya hay paquetes bloqueados o configurados. Verifícalo manualmente."
    fi
fi

echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}   INSTALACIÓN FINALIZADA   ${NC}"
echo -e "${GREEN}=================================================${NC}"
echo -e "${YELLOW}IMPORTANTE:${NC}"
echo "1. Reinicia tu sistema ahora."
echo "2. En el menú de arranque, selecciona el Kernel 'linux-lts-amd-bc250'."
echo "3. Disfruta de tu BC-250 totalmente funcional."
