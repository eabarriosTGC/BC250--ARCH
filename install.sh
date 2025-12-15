#!/bin/bash

# =================================================================================
#  AMD BC-250: ULTIMATE SETUP (FAST TRACK EDITION)
#  Soporta: Instalación de binarios pre-compilados O compilación desde fuente.
# =================================================================================

# --- CONFIGURACIÓN DE DESCARGA ---
# URL base de tu Release v1.0
RELEASE_URL="https://github.com/eabarriosTGC/BC250--ARCH/releases/download/v1.0"

# Nombres exactos de los archivos (Basados en tu compilación exitosa)
# NOTA: Si en el futuro actualizas versiones, cambia esto.
KERNEL_PKG="linux-lts-amd-bc250-6.6.66-9-x86_64.pkg.tar.zst"
KERNEL_HDR="linux-lts-amd-bc250-headers-6.6.66-9-x86_64.pkg.tar.zst"
MESA_PKG="mesa-amd-bc250-24.3.1-8-x86_64.pkg.tar.zst"
VULKAN_PKG="vulkan-radeon-amd-bc250-24.3.1-8-x86_64.pkg.tar.zst"
LIB32_MESA_PKG="lib32-mesa-amd-bc250-24.3.1-1-x86_64.pkg.tar.zst"
LIB32_VULKAN_PKG="lib32-vulkan-radeon-amd-bc250-24.3.1-1-x86_64.pkg.tar.zst"
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

if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}ERROR: No ejecutes como root.${NC}" 
   exit 1
fi

# --- FUNCIONES ---

install_binary() {
    local url="$1"
    local file="$2"
    
    echo -e "${YELLOW}Procesando $file...${NC}"
    
    # Verificar si ya existe localmente para no descargar doble
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}Descargando de GitHub...${NC}"
        # Usamos curl con -L para seguir redirecciones de GitHub
        curl -L -O --progress-bar "$url/$file"
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error descargando $file. Verifica tu internet o si el archivo existe en el Release.${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}Archivo local detectado. Saltando descarga.${NC}"
    fi
    
    echo -e "${GREEN}Instalando...${NC}"
    sudo pacman -U --noconfirm "$file" --overwrite '*'
}

build_source() {
    local pkg_dir=$1
    echo -e "${YELLOW}>>> Compilando desde código fuente: $pkg_dir...${NC}"
    cd "$pkg_dir" || exit
    makepkg -si --noconfirm
    cd ../..
}

# --- 1. MODO DE INSTALACIÓN ---
echo ""
echo "Selecciona el modo de instalación:"
echo -e "  1) ${GREEN}RÁPIDO${NC}: Descargar e instalar binarios pre-compilados (Recomendado)."
echo -e "  2) ${YELLOW}LENTO${NC}: Compilar todo desde cero (Tarda 1-2 horas)."
read -p "Opción (1/2): " install_mode

# --- 2. DEPENDENCIAS ---
echo -e "${GREEN}[1/5] Verificando dependencias...${NC}"
sudo pacman -S --needed --noconfirm base-devel git python rust gcc curl wget

# --- 3. KERNEL ---
echo ""
echo -e "${BLUE}--- KERNEL LTS (BC-250) ---${NC}"
read -p "¿Instalar Kernel LTS parcheado? (s/n): " k_opt
if [[ "$k_opt" =~ ^[Ss]$ ]]; then
    if [ "$install_mode" == "1" ]; then
        install_binary "$RELEASE_URL" "$KERNEL_PKG"
        install_binary "$RELEASE_URL" "$KERNEL_HDR"
    else
        build_source "pkgs/linux-lts-bc250"
    fi
    
    # Fix initramfs bug
    echo "Regenerando initramfs y GRUB..."
    sudo mkinitcpio -P
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# --- 4. MESA (GRAFICOS) ---
echo ""
echo -e "${BLUE}--- MESA (DRIVERS 64-BIT) ---${NC}"
read -p "¿Instalar Drivers Gráficos Parcheados? (s/n): " m_opt
if [[ "$m_opt" =~ ^[Ss]$ ]]; then
    # Limpieza previa
    sudo pacman -Rdd --noconfirm mesa vulkan-radeon vulkan-mesa-implicit-layers 2>/dev/null

    if [ "$install_mode" == "1" ]; then
        install_binary "$RELEASE_URL" "$MESA_PKG"
        install_binary "$RELEASE_URL" "$VULKAN_PKG"
    else
        build_source "pkgs/mesa-bc250"
    fi
    
    # Fix manual de archivos (por si acaso)
    if [ ! -f /usr/lib/libvulkan_radeon.so ]; then
        echo "Aplicando fix de Vulkan 64-bit..."
        # Buscar en local o en build
        if [ -f "libvulkan_radeon.so" ]; then 
             sudo cp libvulkan_radeon.so /usr/lib/
        else
             find pkgs/mesa-bc250 -name "libvulkan_radeon.so" -exec sudo cp {} /usr/lib/ \; -quit
        fi
        
        echo '{"ICD":{"api_version":"1.3.296","library_path":"/usr/lib/libvulkan_radeon.so"},"file_format_version":"1.0.0"}' | sudo tee /usr/share/vulkan/icd.d/radeon_icd.x86_64.json >/dev/null
    fi
fi

# --- 5. LIB32 MESA ---
echo ""
echo -e "${BLUE}--- MESA 32-BIT (STEAM/WINE) ---${NC}"
read -p "¿Instalar librerías de 32 bits? (s/n): " m32_opt
if [[ "$m32_opt" =~ ^[Ss]$ ]]; then
    # Activar multilib si no está
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo "Activando repositorio multilib..."
        sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
        sudo pacman -Syu --noconfirm
    fi

    sudo pacman -Rdd --noconfirm lib32-mesa lib32-vulkan-radeon lib32-vulkan-mesa-implicit-layers 2>/dev/null

    if [ "$install_mode" == "1" ]; then
        install_binary "$RELEASE_URL" "$LIB32_MESA_PKG"
        install_binary "$RELEASE_URL" "$LIB32_VULKAN_PKG"
    else
        build_source "pkgs/lib32-mesa-bc250"
    fi
    
    # Fix manual de archivos 32 bits
    if [ ! -f /usr/lib32/libvulkan_radeon.so ]; then
        echo "Aplicando fix de Vulkan 32-bit..."
        find pkgs/lib32-mesa-bc250 -name "libvulkan_radeon.so" -exec sudo cp {} /usr/lib32/ \; -quit
        echo '{"ICD":{"api_version":"1.3.296","library_path":"/usr/lib32/libvulkan_radeon.so"},"file_format_version":"1.0.0"}' | sudo tee /usr/share/vulkan/icd.d/radeon_icd.i686.json >/dev/null
    fi
fi

# --- 6. GOVERNOR ---
echo ""
echo -e "${BLUE}--- GOVERNOR (RENDIMIENTO) ---${NC}"
read -p "¿Instalar Governor en Rust? (s/n): " g_opt
if [[ "$g_opt" =~ ^[Ss]$ ]]; then
    # Limpieza
    sudo systemctl stop cyan-skillfish-governor 2>/dev/null
    
    # Instalación
    rm -rf cyan-skillfish-governor
    git clone https://github.com/Magnap/cyan-skillfish-governor.git
    cd cyan-skillfish-governor || exit
    cargo build --release
    sudo cp target/release/cyan-skillfish-governor /usr/local/bin/
    cd ..
    rm -rf cyan-skillfish-governor

    # Configuración Segura (1800MHz)
    sudo mkdir -p /etc/cyan-skillfish-governor/
    echo '[load-target]
upper = 0.95
lower = 0.80
[[safe-points]]
mhz = 350
mv = 750
[[safe-points]]
mhz = 1200
mv = 850
[[safe-points]]
mhz = 1800
mv = 950' | sudo tee /etc/cyan-skillfish-governor/config.toml >/dev/null

    # Servicio
    sudo tee /etc/systemd/system/cyan-skillfish-governor.service > /dev/null <<EOT
[Unit]
Description=Cyan Skillfish Governor
After=multi-user.target
[Service]
Type=simple
ExecStart=/usr/local/bin/cyan-skillfish-governor
Restart=always
[Install]
WantedBy=multi-user.target
EOT
    
    # Kernel Param Fix
    if ! grep -q "amdgpu.ppfeaturemask" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&amdgpu.ppfeaturemask=0xffffffff /' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
    
    # Modprobe Fix
    echo "options amdgpu sg_display=0" | sudo tee /etc/modprobe.d/amdgpu.conf

    sudo systemctl daemon-reload
    sudo systemctl enable --now cyan-skillfish-governor.service
fi

# --- 7. BLOQUEO ---
echo ""
read -p "¿Bloquear actualizaciones de estos paquetes? (s/n): " l_opt
if [[ "$l_opt" =~ ^[Ss]$ ]]; then
    PKG_LIST="linux-lts-amd-bc250 mesa-amd-bc250 vulkan-radeon-amd-bc250 lib32-mesa-amd-bc250 lib32-vulkan-radeon-amd-bc250"
    if ! grep -q "linux-lts-amd-bc250" /etc/pacman.conf; then
        sudo sed -i "s/^#IgnorePkg/IgnorePkg/" /etc/pacman.conf
        sudo sed -i "/^IgnorePkg/ s/$/ $PKG_LIST/" /etc/pacman.conf
    fi
fi

echo -e "${GREEN}¡Instalación completada! Reinicia tu sistema.${NC}"
