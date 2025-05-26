#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) != "0" ]]; then
    echo 'Este script debe ejecutarse como root o con sudo!'
    exit 1
fi

echo "ADVERTENCIA: Este script está diseñado para Arch Linux y asume que tienes los repositorios 'testing' habilitados y Mesa >= 25.1 instalado desde ellos."
echo "Asegúrate también de haber instalado el grupo 'base-devel': sudo pacman -S --needed base-devel"
echo "NOTA: La instalación del gobernador de GPU Oberon ha sido DESHABILITADA por defecto en este script, ya que puede causar inestabilidad/apagones en algunas configuraciones del BC-250."
echo "Si deseas probar Oberon Governor bajo tu propio riesgo, deberás descomentar las secciones correspondientes en el script."
echo "Presiona Enter para continuar o Ctrl+C para cancelar."
read

# 1. Actualizar el sistema (esto asegurará que tienes la última versión de Mesa de los repos 'testing')
echo "Actualizando el sistema y asegurando que Mesa está al día desde los repositorios 'testing'..."
pacman -Syu --noconfirm

# 2. Establecer la variable de entorno RADV_DEBUG
echo -n "Configurando la variable de entorno RADV_DEBUG=nocompute... "
# Crear o añadir a /etc/environment. Usar /etc/profile.d/ para un enfoque más modular.
# Línea modificada:
mkdir -p /etc/environment.d/
echo 'RADV_DEBUG=nocompute' > /etc/environment.d/99-bc250-radv.conf
# Nota: /etc/environment se lee al inicio de sesión. /etc/environment.d/ es más flexible.
# Para que el cambio tenga efecto inmediato en la sesión actual del script, también se podría exportar,
# pero para el sistema en general, el archivo de configuración es lo correcto.
echo "OK. Necesitarás reiniciar o cerrar y volver a iniciar sesión para que este cambio global tenga efecto."

# 3. Instalar el gobernador de la GPU de Segfault (Oberon Governor) - DESHABILITADO POR DEFECTO
# ============================================================================================
# INICIO DE SECCIÓN OBERON GOVERNOR (DESHABILITADA)
# ============================================================================================
# echo "Instalando el gobernador de la GPU (Oberon Governor)... "
# # Dependencias para Arch (g++ es parte de gcc, libdrm-devel es libdrm)
# # Asegurarse de que mkinitcpio está instalado
# # Añadir git, cmake, make, gcc SOLO si se va a instalar Oberon. libdrm y mkinitcpio son útiles de todas formas.
# pacman -S --needed --noconfirm libdrm mkinitcpio # git cmake make gcc
#
# # Clonar, compilar e instalar
# TEMP_DIR_OBERON=$(mktemp -d -t oberon-XXXXXX)
# trap 'rm -rf -- "$TEMP_DIR_OBERON"' EXIT # Limpiar el directorio temporal al salir
#
# git clone https://gitlab.com/mothenjoyer69/oberon-governor.git "$TEMP_DIR_OBERON/oberon-governor"
# cd "$TEMP_DIR_OBERON/oberon-governor"
# cmake . && make && make install
# cd / # Volver al directorio raíz o a un lugar seguro
#
# # Habilitar el servicio del gobernador
# systemctl enable oberon-governor.service
# echo "Gobernador de GPU instalado y servicio habilitado. ¡ÚSALO BAJO TU PROPIO RIESGO!"
# ============================================================================================
# FIN DE SECCIÓN OBERON GOVERNOR (DESHABILITADA)
# ============================================================================================
echo "La instalación del gobernador de GPU Oberon ha sido OMITIDA."
echo "Si experimentas problemas de rendimiento y quieres probarlo, edita este script y descomenta la sección correspondiente."

# 4. Asegurar que las opciones de los módulos amdgpu y nct6683 están en los archivos modprobe y actualizar initramfs
echo "Asegurando dependencias necesarias para módulos y sensores..."
pacman -S --needed --noconfirm libdrm mkinitcpio lm_sensors # lm_sensors para la utilidad 'sensors'

echo -n "Configurando la opción del módulo amdgpu (sg_display=0)... "
# Esta opción es para kernels < 6.11 según la documentación. Puede que no sea necesaria en kernels más nuevos.
echo 'options amdgpu sg_display=0' > /etc/modprobe.d/amdgpu-bc250.conf
echo "OK"

echo -n "Configurando la carga y opción del módulo nct6683 para sensores... "
echo 'nct6683' > /etc/modules-load.d/nct6683-bc250.conf
echo 'options nct6683 force=true' > /etc/modprobe.d/nct6683-bc250.conf
echo "OK"

echo "Regenerando initramfs (esto puede tardar un momento)..."
# En Arch, se usa mkinitcpio en lugar de dracut
mkinitcpio -P
echo "OK"

# 5. Recordatorios finales y reinicio
echo ""
echo "¡Configuración básica completada!"
echo "---------------------------------------------------------------------"
echo "RESUMEN DE CAMBIOS IMPORTANTES:"
echo "- Sistema actualizado."
echo "- RADV_DEBUG=nocompute configurado (requiere reinicio/re-login para efecto global)."
echo "- Opciones de kernel para amdgpu (sg_display=0) y nct6683 (force=true) configuradas."
echo "- Initramfs regenerado."
echo "- ¡El gobernador de GPU Oberon NO fue instalado!"
echo "---------------------------------------------------------------------"
echo "COSAS A VERIFICAR DESPUÉS DEL REINICIO:"
echo "1. `echo \$RADV_DEBUG` (debería ser 'nocompute' después de re-login)."
echo "2. `cat /sys/module/amdgpu/parameters/sg_display` (debería ser 0)."
echo "3. `lsmod | grep nct6683` (debería mostrar el módulo)."
echo "4. `sensors` (debería mostrar lecturas del nct6686)."
echo "5. `cat /proc/cmdline` (ASEGÚRATE que 'nomodeset' NO esté presente)."
echo "6. `glxinfo | grep \"OpenGL version string\"` (debería mostrar Mesa >= 25.1)."
echo "7. `vulkaninfo --summary | grep driverName` (debería ser 'radv')."
echo "---------------------------------------------------------------------"
echo "Se recomienda reiniciar el sistema para que todos los cambios surtan efecto."
echo "El sistema se reiniciará en 30 segundos. Presiona Ctrl-C para cancelar el reinicio."
sleep 30 && systemctl reboot
