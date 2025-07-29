#!/usr/bin/env bash
set -euo pipefail

# --- Colores para la salida ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[0;34m'
C_NC='\033[0m' # Sin color

# --- Funciones Auxiliares ---

# Imprime un mensaje de encabezado
function print_header() {
    echo -e "\n${C_BLUE}--- $1 ---${C_NC}"
}

# Imprime un mensaje de éxito
function print_success() {
    echo -e "${C_GREEN}OK: $1${C_NC}"
}

# Imprime una advertencia
function print_warning() {
    echo -e "${C_YELLOW}ADVERTENCIA: $1${C_NC}"
}

# Imprime un error y sale
function die() {
    echo -e "${C_RED}ERROR: $1${C_NC}" >&2
    exit 1
}

# --- Funciones Principales ---

function check_root() {
    if [[ $(id -u) != "0" ]]; then
        die "Este script debe ejecutarse como root o con sudo."
    fi
}

function initial_warnings() {
    print_header "Configuración para AMD BC-250 en Arch Linux"
    print_warning "Este script está optimizado para la BC-250 con kernels >= 6.15 y Mesa >= 25.1 (ahora en repos estables)."
    echo "Se realizarán los siguientes cambios:"
    echo "  - Se instalará el grupo 'base-devel' si no está presente."
    echo "  - Se configurará RADV_DEBUG=nocompute."
    echo "  - Se configurarán los módulos del kernel 'amdgpu' y 'nct6683'."
    echo "  - Se regenerará el initramfs."
    echo "  - Se instalará el gobernador de GPU Oberon (experimental)."
    print_warning "NOTA: Se asume que tu sistema ya está actualizado (pacman -Syu). Si no lo has hecho recientemente, ¡hazlo ahora!"
    print_warning "Presiona Enter para continuar o Ctrl+C para cancelar."
    read -r
}

function check_prerequisites() {
    print_header "Verificando prerrequisitos"

    # 1. Comprobar si 'base-devel' está instalado
    if ! pacman -Qg base-devel &>/dev/null; then
        print_warning "El grupo de paquetes 'base-devel' no está instalado."
        read -p "¿Deseas instalarlo ahora? (Requerido para compilar Oberon) [S/n]: " choice
        case "$choice" in
            n|N) die "El grupo 'base-devel' es requerido para este script. Saliendo." ;;
            *)
                pacman -S --needed --noconfirm base-devel
                print_success "'base-devel' instalado."
                ;;
        esac
    else
        print_success "El grupo 'base-devel' ya está instalado."
    fi
    
    # Mesa >= 25.1 ya está en los repos estables de Arch, no es necesario checkear 'testing'.
    print_success "Mesa >= 25.1 se espera que ya esté instalado desde los repositorios oficiales."
}

function install_base_deps() {
    print_header "Instalando dependencias base necesarias"
    # No se hace un pacman -Syu completo aquí, se espera que el usuario lo haga.
    # Solo instalamos los paquetes que puedan faltar para la funcionalidad básica.
    local packages=(
        "libdrm"
        "mkinitcpio"
        "lm_sensors"
        # mesa, vulkan-radeon, libva-mesa-driver, mesa-vdpau, glxinfo, vulkan-tools
        # se asume que ya están presentes o se instalarán con gnome/kde o una actualización normal
    )
    
    echo "Instalando paquetes base necesarios: ${packages[*]}"
    pacman -S --needed --noconfirm "${packages[@]}"
    print_success "Dependencias base instaladas."
}

function configure_radv() {
    print_header "Configurando entorno de RADV"
    local env_file="/etc/environment.d/99-radv-bc250.conf"
    local env_var="RADV_DEBUG=nocompute"

    if [[ -f "$env_file" ]] && grep -qF "$env_var" "$env_file"; then
        print_success "RADV_DEBUG ya está configurado en $env_file."
    else
        mkdir -p /etc/environment.d/
        echo "$env_var" > "$env_file"
        print_success "Variable RADV_DEBUG=nocompute configurada en $env_file."
        print_warning "Necesitarás reiniciar o volver a iniciar sesión para que este cambio tenga efecto."
    fi
}

function configure_modules() {
    print_header "Configurando módulos del kernel"

    # Configurar amdgpu
    local amdgpu_conf="/etc/modprobe.d/amdgpu-bc250.conf"
    local amdgpu_opts="options amdgpu sg_display=0"
    if [[ -f "$amdgpu_conf" ]] && grep -qF "$amdgpu_opts" "$amdgpu_conf"; then
        print_success "Opciones de amdgpu ya configuradas."
    else
        echo "$amdgpu_opts" > "$amdgpu_conf"
        print_success "Opción 'sg_display=0' configurada para amdgpu."
    fi

    # Configurar nct6683 para los sensores
    local nct_load_conf="/etc/modules-load.d/nct6683-bc250.conf"
    local nct_mod_conf="/etc/modprobe.d/nct6683-bc250.conf"
    local nct_opts="options nct6683 force=true"
    
    echo "nct6683" > "$nct_load_conf"
    echo "$nct_opts" > "$nct_mod_conf"
    print_success "Módulo nct6683 configurado para cargarse y con la opción 'force=true'."
    
    print_header "Regenerando initramfs"
    echo "Esto puede tardar un momento..."
    mkinitcpio -P
    print_success "Initramfs regenerado."
}

# --- SECCIÓN OBERON GOVERNOR ---
function install_oberon_governor() {
    print_header "Instalando Oberon Governor (BAJO TU PROPIO RIESGO)"
    
    read -p "Esta función es experimental y puede causar inestabilidad. ¿Estás seguro de que quieres continuar? [s/N]: " choice
    if [[ "$choice" != "s" && "$choice" != "S" ]]; then
        echo "Instalación de Oberon Governor cancelada por el usuario."
        return
    fi
    
    # Dependencias específicas para Oberon
    print_success "Instalando dependencias para la compilación: git, cmake, make, gcc"
    pacman -S --needed --noconfirm git cmake make gcc
    
    local temp_dir
    temp_dir=$(mktemp -d -t oberon-XXXXXX)
    # Limpiar el directorio temporal al salir del script, sin importar cómo
    trap 'echo "Limpiando directorio temporal..."; rm -rf -- "$temp_dir"' EXIT
    
    echo "Clonando el repositorio de Oberon Governor..."
    git clone https://gitlab.com/mothenjoyer69/oberon-governor.git "$temp_dir/oberon-governor"
    
    cd "$temp_dir/oberon-governor"
    
    echo "Compilando e instalando..."
    if cmake . && make && make install; then
        print_success "Oberon Governor compilado e instalado correctamente."
        echo "Habilitando el servicio systemd..."
        systemctl enable oberon-governor.service
        print_success "Servicio oberon-governor.service habilitado."
        print_warning "Si experimentas cuelgues, deshabilita el servicio con: sudo systemctl disable oberon-governor.service"
    else
        die "La compilación o instalación de Oberon Governor falló. Revisa la salida de errores."
    fi

    cd / # Volver a un directorio seguro
}

function final_summary() {
    print_header "¡Configuración completada!"
    echo "---------------------------------------------------------------------"
    echo "RESUMEN DE CAMBIOS:"
    echo " ✓ Dependencias base y 'base-devel' instaladas."
    echo " ✓ RADV_DEBUG=nocompute configurado."
    echo " ✓ Opciones de kernel para amdgpu y nct6683 aplicadas."
    echo " ✓ Initramfs regenerado."
    if systemctl is-enabled oberon-governor.service &>/dev/null; then
        echo -e " ${C_GREEN}✓ El gobernador de GPU Oberon fue instalado y habilitado.${C_NC}"
    else
        echo -e " ${C_YELLOW}✗ El gobernador de GPU Oberon NO fue instalado (posiblemente cancelado por el usuario).${C_NC}"
    fi
    echo "---------------------------------------------------------------------"
    echo "COSAS A VERIFICAR DESPUÉS DEL REINICIO:"
    echo "1. Inicia sesión y ejecuta: ${C_GREEN}echo \$RADV_DEBUG${C_NC} (debe ser 'nocompute')"
    echo "2. Ejecuta: ${C_GREEN}cat /sys/module/amdgpu/parameters/sg_display${C_NC} (debe ser 0)"
    echo "3. Ejecuta: ${C_GREEN}lsmod | grep nct6683${C_NC} (debe aparecer)"
    echo "4. Ejecuta: ${C_GREEN}sudo sensors${C_NC} (debe mostrar lecturas del nct6683/6)"
    echo "5. Ejecuta: ${C_GREEN}cat /proc/cmdline${C_NC} (ASEGÚRATE que 'nomodeset' NO esté)"
    echo "6. Ejecuta: ${C_GREEN}glxinfo | grep \"OpenGL version string\"${C_NC} (debe mostrar Mesa >= 25.1)"
    echo "7. Ejecuta: ${C_GREEN}vulkaninfo --summary | grep driverName${C_NC} (debe ser 'radv')"
    echo "8. Ejecuta: ${C_GREEN}systemctl status oberon-governor.service${C_NC} (debe mostrar 'active (running)')"
    echo "---------------------------------------------------------------------"

    read -p "¿Deseas reiniciar el sistema ahora para aplicar todos los cambios? [S/n]: " choice
    case "$choice" in
        n|N) echo "Recuerda reiniciar manualmente para que todos los cambios surtan efecto." ;;
        *)
            echo "Reiniciando en 5 segundos..."
            sleep 5
            systemctl reboot
            ;;
    esac
}

# --- Flujo de Ejecución Principal ---
function main() {
    check_root
    initial_warnings
    check_prerequisites
    install_base_deps # Solo instala dependencias base, no hace un pacman -Syu completo
    configure_radv
    configure_modules
    
    # La instalación de Oberon Governor está activada por defecto.
    install_oberon_governor
    
    final_summary
}

# Ejecutar la función principal pasando todos los argumentos del script
main "$@"
