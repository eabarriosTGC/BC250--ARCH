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
