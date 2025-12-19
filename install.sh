#!/bin/bash

# =================================================================================
#  AMD BC-250: ULTIMATE SETUP (FAST TRACK EDITION)
#  Soporta: Instalación de binarios pre-compilados O compilación desde fuente.
# =================================================================================
# --- CONFIGURACIÓN DE DESCARGA ---
# URL actualizada a la versión v1.2
RELEASE_URL="https://github.com/eabarriosTGC/BC250--ARCH/releases/download/v1.2"

# Nombres exactos (Basados en tu compilación final)
KERNEL_PKG="linux-lts-amd-bc250-6.6.66-9-x86_64.pkg.tar.zst"
KERNEL_HDR="linux-lts-amd-bc250-headers-6.6.66-9-x86_64.pkg.tar.zst"

# Mesa 64-bits (Versión -9)
MESA_PKG="mesa-amd-bc250-1.24.3.1-9-x86_64.pkg.tar.zst"
VULKAN_PKG="vulkan-radeon-amd-bc250-1.24.3.1-9-x86_64.pkg.tar.zst"

# Mesa 32-bits (Versión -2)
LIB32_MESA_PKG="lib32-mesa-amd-bc250-1.24.3.1-2-x86_64.pkg.tar.zst"
LIB32_VULKAN_PKG="lib32-vulkan-radeon-amd-bc250-1.24.3.1-2-x86_64.pkg.tar.zst"
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
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}Descargando de GitHub...${NC}"
        curl -L -O --progress-bar "$url/$file"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error descargando. Verifica internet.${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}Archivo local detectado.${NC}"
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
echo -e "  1) ${GREEN}RÁPIDO${NC}: Descargar binarios (Recomendado)."
echo -e "  2) ${YELLOW}LENTO${NC}: Compilar desde cero (1-2 horas)."
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
    
    echo "Regenerando initramfs y GRUB..."
    sudo mkinitcpio -P
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# --- 4. MESA (GRAFICOS) ---
echo ""
echo -e "${BLUE}--- MESA (DRIVERS 64-BIT) ---${NC}"
read -p "¿Instalar Drivers Gráficos Parcheados? (s/n): " m_opt
if [[ "$m_opt" =~ ^[Ss]$ ]]; then
    sudo pacman -Rdd --noconfirm mesa vulkan-radeon vulkan-mesa-implicit-layers 2>/dev/null

    if [ "$install_mode" == "1" ]; then
        install_binary "$RELEASE_URL" "$MESA_PKG"
        install_binary "$RELEASE_URL" "$VULKAN_PKG"
    else
        build_source "pkgs/mesa-bc250"
    fi
    
    # --- FORCE FIX VULKAN 64-BIT (SI O SI) ---
    echo "Asegurando configuración de Vulkan (64-bit)..."
    
    # 1. Si compilamos, copiamos el driver manualmente por seguridad
    LIB_SRC=$(find pkgs/mesa-bc250 -name "libvulkan_radeon.so" 2>/dev/null | head -n 1)
    if [ -f "$LIB_SRC" ]; then
        echo "Copiando driver compilado a /usr/lib/..."
        sudo cp "$LIB_SRC" /usr/lib/
    fi

    # 2. Regenerar SIEMPRE el JSON para apuntar al lugar correcto
    echo "Generando JSON correcto para Vulkan..."
    echo '{
    "ICD": {
        "api_version": "1.3.296",
        "library_path": "/usr/lib/libvulkan_radeon.so"
    },
    "file_format_version": "1.0.0"
}' | sudo tee /usr/share/vulkan/icd.d/radeon_icd.x86_64.json >/dev/null
fi

# --- 5. LIB32 MESA ---
echo ""
echo -e "${BLUE}--- MESA 32-BIT (STEAM/WINE) ---${NC}"
read -p "¿Instalar librerías de 32 bits? (s/n): " m32_opt
if [[ "$m32_opt" =~ ^[Ss]$ ]]; then
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
    
    # --- FORCE FIX VULKAN 32-BIT (SI O SI) ---
    echo "Asegurando configuración de Vulkan (32-bit)..."
    
    LIB32_SRC=$(find pkgs/lib32-mesa-bc250 -name "libvulkan_radeon.so" 2>/dev/null | head -n 1)
    if [ -f "$LIB32_SRC" ]; then
        echo "Copiando driver compilado a /usr/lib32/..."
        sudo cp "$LIB32_SRC" /usr/lib32/
    fi

    echo '{
    "ICD": {
        "api_version": "1.3.296",
        "library_path": "/usr/lib32/libvulkan_radeon.so"
    },
    "file_format_version": "1.0.0"
}' | sudo tee /usr/share/vulkan/icd.d/radeon_icd.i686.json >/dev/null
fi

# --- 6. GOVERNOR ---
echo ""
echo -e "${BLUE}--- GOVERNOR (RENDIMIENTO) ---${NC}"
read -p "¿Instalar Governor en Rust? (s/n): " g_opt
if [[ "$g_opt" =~ ^[Ss]$ ]]; then
    sudo systemctl stop cyan-skillfish-governor 2>/dev/null
    
    rm -rf cyan-skillfish-governor
    git clone https://github.com/Magnap/cyan-skillfish-governor.git
    cd cyan-skillfish-governor || exit
    cargo build --release
    sudo cp target/release/cyan-skillfish-governor /usr/local/bin/
    cd ..
    rm -rf cyan-skillfish-governor

    # Configuración Gaming (2000MHz)
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
mhz = 2000
mv = 950' | sudo tee /etc/cyan-skillfish-governor/config.toml >/dev/null

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
    
    if ! grep -q "amdgpu.ppfeaturemask" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&amdgpu.ppfeaturemask=0xffffffff /' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
    
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
