#!/usr/bin/env bash
set -euo pipefail

# --- Colores para la salida ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[0;34m'
C_NC='\033[0m' # Sin color

# --- Funciones Auxiliares ---
function print_header() { echo -e "\n${C_BLUE}--- $1 ---${C_NC}"; }
function print_success() { echo -e "${C_GREEN}OK: $1${C_NC}"; }
function print_warning() { echo -e "${C_YELLOW}ADVERTENCIA: $1${C_NC}"; }
function die() { echo -e "${C_RED}ERROR: $1${C_NC}" >&2; exit 1; }

# --- Flujo Principal ---

# 1. Verificar si se ejecuta como root
if [[ $(id -u) != "0" ]]; then
    die "Este script debe ejecutarse como root o con sudo."
fi

# 2. Mensajes iniciales y confirmación del usuario
print_header "Optimizador Completo para AMD BC-250 en Manjaro"
echo "Este script aplicará los siguientes ajustes para mejorar la estabilidad y el rendimiento:"
echo "  1. Instalará Oberon Governor para el control de frecuencias (si no está ya)."
echo "  2. Configurará RADV_DEBUG=nocompute para reducir el stuttering en Vulkan."
echo "  3. Aplicará opciones a los módulos del kernel 'amdgpu' y 'nct6683'."
echo "  4. Regenerará el initramfs para aplicar los cambios en el arranque."
print_warning "Este script es seguro de ejecutar varias veces."
read -p "Presiona Enter para continuar o Ctrl+C para cancelar."

# 3. Instalar dependencias necesarias
print_header "Instalando dependencias necesarias"
# CORRECCIÓN: --noconfirm en lugar de --nocomfirm
pacman -S --needed --noconfirm base-devel git cmake lm_sensors
print_success "Dependencias verificadas/instaladas."

# 4. Configurar la variable de entorno RADV
print_header "Configurando RADV_DEBUG para estabilidad"
mkdir -p /etc/environment.d/
echo 'RADV_DEBUG=nocompute' > /etc/environment.d/99-radv-bc250.conf
print_success "Variable RADV_DEBUG=nocompute configurada."
print_warning "Necesitarás reiniciar para que este cambio tenga efecto global."

# 5. Configurar los módulos del kernel
print_header "Configurando módulos del kernel"
# Opción para amdgpu
echo 'options amdgpu sg_display=0' > /etc/modprobe.d/amdgpu-bc250.conf
print_success "Opción 'sg_display=0' configurada para amdgpu."

# Opciones para los sensores nct6683
echo 'nct6683' > /etc/modules-load.d/nct6683-bc250.conf
echo 'options nct6683 force=true' > /etc/modprobe.d/nct6683-bc250.conf
print_success "Módulo de sensores nct6683 configurado para cargarse."

# 6. Regenerar initramfs
print_header "Regenerando initramfs"
# Manjaro, al igual que Arch, usa mkinitcpio
mkinitcpio -P
print_success "Initramfs regenerado."

# 7. Instalar Oberon Governor (si no está ya)
print_header "Instalando/Verificando Oberon Governor"
TEMP_DIR=$(mktemp -d -t oberon-XXXXXX)
trap 'rm -rf -- "$TEMP_DIR"' EXIT

echo "Clonando y compilando Oberon Governor..."
git clone https://gitlab.com/mothenjoyer69/oberon-governor.git "$TEMP_DIR/oberon-governor"
cd "$TEMP_DIR/oberon-governor"

if cmake . && make && make install; then
    print_success "Oberon Governor compilado e instalado correctamente."
    systemctl enable oberon-governor.service
    print_success "Servicio 'oberon-governor.service' habilitado."
else
    die "La compilación o instalación de Oberon Governor falló."
fi
cd /

# 8. Resumen final y reinicio
print_header "¡Configuración completada!"
echo "---------------------------------------------------------------------"
echo "RESUMEN DE CAMBIOS APLICADOS:"
echo " ✓ Dependencias de compilación y sensores instaladas."
echo " ✓ RADV_DEBUG=nocompute configurado para reducir stuttering."
echo " ✓ Opciones de kernel para amdgpu y nct6683 aplicadas."
echo " ✓ Oberon Governor instalado y habilitado."
echo " ✓ Initramfs regenerado."
echo "---------------------------------------------------------------------"
echo "Se recomienda reiniciar para que TODOS los cambios surtan efecto."
echo "Después de reiniciar, verifica el rendimiento y monitoriza las temperaturas con 'sudo sensors'."
echo "---------------------------------------------------------------------"

read -p "¿Deseas reiniciar el sistema ahora? [S/n]: " choice
case "$choice" in
    n|N) echo "Recuerda reiniciar manualmente." ;;
    *)
        echo "Reiniciando en 5 segundos..."
        sleep 5
        systemctl reboot
        ;;
esac

exit 0
