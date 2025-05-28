Configuración y Optimización para GPUs BC-250 en Arch Linux y Derivadas

Este repositorio contiene scripts y documentación para configurar y optimizar el soporte de la placa BC-250 en sistemas Arch Linux y derivadas. El objetivo es facilitar la instalación de Mesa 25.++ desde los repositorios testing y ajustar configuraciones clave para mejorar la estabilidad y el rendimiento.
Requisitos Previos
Activar repositorios Testing

    sudo nano /etc/pacman.conf

Debes activar los siguientes repositorios:

    core-testing

    extra-testing

    multilib-testing

Esto es necesario para instalar Mesa 25.++ y sus dependencias en versiones compatibles.
Instalación de dependencias esenciales

Ejecuta el siguiente comando para instalar los paquetes necesarios:

    sudo pacman -S base-devel git meson ninja python-mako libdrm libxrandr libx11 libxext libxxf86vm libxcb wayland libva elfutils libomxil-bellagio libunwind vulkan-headers glslang fakeroot

Uso del Script

El script incluido en este repositorio realiza los siguientes pasos:

    Actualiza el sistema con los paquetes de los repositorios testing.

    Establece la variable de entorno RADV_DEBUG=nocompute.

    Configura opciones para los módulos del kernel:

        amdgpu con la opción sg_display=0.

        nct6683 con la opción force=true.

    Regenera el initramfs utilizando mkinitcpio.

    Instala Mesa 25.++ y todas sus dependencias desde los repositorios testing en la misma versión.

Detalles Importantes

    Las distribuciones basadas en Arch Linux ya incluyen Mesa 25.++ en sus repositorios testing, facilitando la instalación sin necesidad de parches adicionales.

    Todos los archivos necesarios y configuraciones están incluidos en este repositorio para que puedas personalizar según tus necesidades.

Cómo contribuir

Si deseas colaborar:

    Reporta cualquier error o problema usando las issues.

    Envía pull requests con mejoras o correcciones, manteniendo el estilo y la compatibilidad para Arch y derivadas.


Fuente principal para hacer posible esto:
(https://github.com/mothenjoyer69/bc250-documentation)

Licencia

Este proyecto está licenciado bajo MIT.
