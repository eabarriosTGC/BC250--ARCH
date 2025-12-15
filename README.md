# 🚀 AMD BC-250 (Cyan Skillfish): Ultimate Arch Linux Setup

> **Estado:** ✅ Estable / Probado en Diciembre 2025  
> **Soporte:** Arch Linux, Manjaro, EndeavourOS (Kernel 6.6 LTS + Mesa 24.3)  
> **Características:** Instalador Automático, Soporte Binario (Releases), Fixes para GCC 15/LLVM 21.

Este repositorio contiene la solución definitiva para estabilizar la placa **AMD BC-250** (una APU de PS5 reutilizada) en Arch Linux. Soluciona problemas de pantalla negra, falta de aceleración, errores de compilación modernos y cuelgues de GPU (Green Screen).

---

## ⚡ Novedad: Instalación Rápida (Fast Track)
¡Ya no necesitas esperar 2 horas compilando! Este script ahora te permite **descargar e instalar automáticamente** los paquetes pre-compilados y optimizados desde [GitHub Releases](https://github.com/eabarriosTGC/BC250--ARCH/releases).

---

## 🛑 El Problema
Si intentas usar esta placa en un Arch Linux actualizado (2024/2025), te encontrarás con:
1.  **Pantalla Negra:** Los Kernels 6.12+ y 6.17+ tienen regresiones con el hardware Cyan Skillfish.
2.  **Errores de Compilación:** El Kernel 6.6 LTS falla al compilar con **GCC 15 (C23 Standard)** debido a conflictos con palabras reservadas (`bool`, `true`).
3.  **Mesa Roto:** Mesa 24.x falla al compilar con **LLVM 21** debido a cambios en la API y módulos OpenCL incompatibles.
4.  **Green Screen of Death:** Cuelgues del sistema al ejecutar cargas pesadas (FurMark, Juegos) por frecuencias inestables (>2000MHz).

## 🛠️ La Solución Técnica
Este repositorio automatiza la corrección de todo lo anterior:

*   **Kernel LTS (6.6.66+) Custom:** Parcheado con "PATH Hijacking" para forzar el estándar `gnu11` en GCC 15, permitiendo una compilación exitosa.
*   **Mesa 24.3 (64 & 32 bits):** Drivers gráficos purgados de módulos OpenCL/Rusticl (rotos en LLVM 21) y parcheados para reconocer la BC-250.
*   **Performance Governor:** Implementación en Rust (por *Magnap*) configurada con un perfil de seguridad (1800MHz) para evitar pantallazos verdes.
*   **Protección:** Bloqueo automático de actualizaciones en `pacman.conf` para evitar roturas futuras.

---

## 🚀 Guía de Instalación

### 1. Clonar el repositorio
Abre una terminal y ejecuta:

```bash
sudo pacman -S git base-devel
git clone https://github.com/eabarriosTGC/BC250--ARCH.git
cd BC250--ARCH
