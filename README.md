    
# 🚀 AMD BC-250 (Cyan Skillfish): Ultimate Arch Linux Setup

> **Estado:** ✅ Estable / Probado en Diciembre 2025  
> **Soporte:** Arch Linux, Manjaro, EndeavourOS (Kernel 6.6 LTS + Mesa 24.3)  
> **Características:** Instalador Automático, Soporte Binario (Releases), Fixes para GCC 15/LLVM 21.

Este repositorio contiene la solución definitiva para hacer funcionar la placa **AMD BC-250** (una APU de PS5 reutilizada) en Arch Linux y derivados. Soluciona problemas de pantalla negra, falta de aceleración, errores de compilación modernos y configura el rendimiento óptimo para juegos.

---

## ⚡ Novedad: Instalación Rápida (Fast Track)
¡Ya no necesitas esperar 2 horas compilando! Este script ahora te permite **descargar e instalar automáticamente** los paquetes pre-compilados y optimizados desde [GitHub Releases](https://github.com/eabarriosTGC/BC250--ARCH/releases).

---

## 🛑 El Problema
Si intentas usar esta placa en un Arch Linux actualizado (2024/2025), te encontrarás con:
1.  **Pantalla Negra:** Los Kernels 6.12+ y 6.17+ tienen regresiones con el hardware Cyan Skillfish.
2.  **Errores de Compilación:** El Kernel 6.6 LTS falla al compilar con **GCC 15 (C23 Standard)** debido a conflictos con palabras reservadas.
3.  **Mesa Roto:** Mesa 24.x falla al compilar con **LLVM 21**.
4.  **Rendimiento:** Sin el governor adecuado, la tarjeta se queda en frecuencias bajas o crashea.

## 🛠️ La Solución Técnica
Este repositorio automatiza la corrección de todo lo anterior:

*   **Kernel LTS (6.6.66+) Custom:** Parcheado con "PATH Hijacking" para forzar el estándar `gnu11` en GCC 15.
*   **Mesa 24.3 (64 & 32 bits):** Drivers gráficos purgados de módulos OpenCL conflictivos y optimizados para gaming.
*   **Performance Governor:** Implementación en Rust (por *Magnap*) configurada a **2000MHz** para máximo rendimiento en juegos.
*   **Protección:** Bloqueo automático de actualizaciones en `pacman.conf`.

---

## 🚀 Guía de Instalación

### 1. Clonar el repositorio
Abre una terminal y ejecuta:

```bash
sudo pacman -S git base-devel
git clone https://github.com/eabarriosTGC/BC250--ARCH.git
cd BC250--ARCH

  

2. Ejecutar el Asistente

Da permisos de ejecución y lanza el script maestro. No uses sudo, el script te pedirá la contraseña cuando sea necesario.
code Bash

    
chmod +x install.sh
./install.sh

  

3. Seleccionar Modo

    Opción 1 (RÁPIDO): Descarga e instala los binarios optimizados (5 minutos). Recomendado.

    Opción 2 (LENTO): Compila todo desde cero en tu máquina (1-2 horas).

4. Seguir los pasos

Responde Sí (s) a todo (Kernel, Mesa, Lib32, Governor).
⚠️ Pasos Post-Instalación

Al terminar, REINICIA tu equipo. Si notas problemas:
A. Verificar Parámetros de Arranque (GRUB)

Si los ventiladores no se controlan o el rendimiento es muy bajo, verifica que GRUB cargó el parámetro:

    sudo nano /etc/default/grub -> Busca: GRUB_CMDLINE_LINUX_DEFAULT="... amdgpu.ppfeaturemask=0xffffffff"

    Actualiza: sudo grub-mkconfig -o /boot/grub/grub.cfg y reinicia.

B. Verificar Drivers Vulkan

Si Steam no abre, verifica que el driver sea detectado:
code Bash

    
vulkaninfo | grep deviceName
# Debe decir: AMD BC-250 (RADV NAVI10)

  

Si dice llvmpipe, copia los drivers manualmente:
code Bash

    
sudo cp pkgs/mesa-bc250/src/build/src/amd/vulkan/libvulkan_radeon.so /usr/lib/
sudo cp pkgs/lib32-mesa-bc250/src/build/src/amd/vulkan/libvulkan_radeon.so /usr/lib32/

  

🎮 Rendimiento y Advertencias

El Governor incluido viene configurado a 2000 MHz.

    ✅ Juegos (Real World): Probado en juegos exigentes como Resident Evil 4 Remake, funcionando fluido y estable a 2000MHz.

    ⚠️ Stress Tests (FurMark/OCCT): NO RECOMENDADO. Herramientas como FurMark generan una carga de energía artificial excesiva que puede causar pantallas verdes (crash) a 2000MHz. Esto no refleja el uso real en juegos.

Si experimentas inestabilidad:
Puedes bajar la frecuencia editando el archivo de configuración:
sudo nano /etc/cyan-skillfish-governor/config.toml (Cambia 2000 por 1800).
📄 Créditos y Licencia

    Automatización y Fixes GCC15/LLVM21: eabarriosTGC

    Rust Governor: Magnap

    Parches Originales: Comunidad BC-250.

Licencia MIT.
