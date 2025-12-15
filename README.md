
# 🚀 AMD BC-250 (Cyan Skillfish) — Arch Linux Ultimate Setup

> **Estado:** ✅ Estable — Probado en diciembre 2025  
> **Soporte:** Arch Linux, Manjaro, EndeavourOS  
> **Kernel:** 6.6 LTS  
> **Stack gráfico:** Mesa 24.3  
> **Incluye:** Instalador automático, binarios precompilados y fixes para GCC 15 / LLVM 21

Este repositorio proporciona la **solución definitiva** para ejecutar la placa  
**AMD BC-250 (Cyan Skillfish, APU de PS5 reutilizada)** en Arch Linux y derivados.

Soluciona:
- Pantalla negra
- Falta de aceleración gráfica
- Errores de compilación modernos
- Rendimiento inestable en juegos

---

## ⚡ Novedad — Instalación Rápida (Fast Track)

Ya no necesitas esperar horas compilando.

El instalador permite **descargar e instalar automáticamente** paquetes
**precompilados y optimizados** desde GitHub Releases:

👉 https://github.com/eabarriosTGC/BC250--ARCH/releases

---

## 🛑 El Problema

En sistemas Arch Linux actualizados (2024/2025), la BC-250 presenta:

1. **Pantalla negra**  
   Kernels `6.12+` y `6.17+` tienen regresiones con hardware Cyan Skillfish.

2. **Errores de compilación**  
   El kernel 6.6 LTS falla con **GCC 15 (C23)** por conflictos con palabras reservadas.

3. **Mesa roto**  
   Mesa 24.x falla al compilar con **LLVM 21**.

4. **Bajo rendimiento**  
   Sin un governor adecuado, la GPU se queda en frecuencias bajas o crashea.

---

## 🛠️ La Solución Técnica

Este repositorio automatiza todo el proceso:

### 🔧 Kernel
- **Linux 6.6 LTS custom (6.6.66+)**
- Parcheado mediante *PATH hijacking* para forzar `gnu11` con GCC 15.

### 🎮 Mesa
- **Mesa 24.3 (64 y 32 bits)**
- Drivers Vulkan/RADV optimizados
- Módulos OpenCL conflictivos eliminados.

### ⚙️ Rendimiento
- **Governor en Rust (por Magnap)**
- Frecuencia fija a **2000 MHz** para gaming.

### 🔒 Protección
- Bloqueo automático de actualizaciones en `pacman.conf`.

---

## 🚀 Guía de Instalación

### 1️⃣ Clonar el repositorio

```bash
sudo pacman -S git base-devel
git clone https://github.com/eabarriosTGC/BC250--ARCH.git
cd BC250--ARCH
````

---

### 2️⃣ Ejecutar el instalador

Da permisos y ejecuta el script principal
(**no uses sudo**, el script lo pedirá cuando sea necesario):

```bash
chmod +x install.sh
./install.sh
```

---

### 3️⃣ Seleccionar modo de instalación

* **Opción 1 — RÁPIDO (recomendado)**
  Descarga binarios optimizados (≈ 5 minutos)

* **Opción 2 — LENTO**
  Compila todo localmente (1–2 horas)

---

### 4️⃣ Seguir el asistente

Responde **Sí (s)** a:

* Kernel
* Mesa
* Lib32 Mesa
* Governor

---

## ⚠️ Post-Instalación (Importante)

### 🔄 Reiniciar el sistema

Al finalizar la instalación, **reinicia obligatoriamente**.

---

### A️⃣ Verificar parámetros de arranque (GRUB)

Si notas bajo rendimiento o problemas con ventiladores:

```bash
sudo nano /etc/default/grub
```

Verifica que exista:

```text
GRUB_CMDLINE_LINUX_DEFAULT="... amdgpu.ppfeaturemask=0xffffffff"
```

Actualiza GRUB y reinicia:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
reboot
```

---

### B️⃣ Verificar Vulkan

Si Steam no abre o no detecta la GPU:

```bash
vulkaninfo | grep deviceName
```

Debe mostrar:

```text
AMD BC-250 (RADV NAVI10)
```

Si aparece `llvmpipe`, copia los drivers manualmente:

```bash
sudo cp pkgs/mesa-bc250/src/build/src/amd/vulkan/libvulkan_radeon.so /usr/lib/
sudo cp pkgs/lib32-mesa-bc250/src/build/src/amd/vulkan/libvulkan_radeon.so /usr/lib32/
```

---

## 🎮 Rendimiento y Advertencias

### ⚙️ Governor

* Configurado por defecto a **2000 MHz**

#### ✅ Uso real (juegos)

* Probado en títulos exigentes como
  **Resident Evil 4 Remake**, estable y fluido.

#### ⚠️ Stress tests (NO recomendado)

* **FurMark / OCCT** generan cargas irreales
* Pueden causar **pantalla verde o crash** a 2000 MHz
* No representan el uso real en juegos

---

### 🔧 Ajustar frecuencia (opcional)

Si experimentas inestabilidad:

```bash
sudo nano /etc/cyan-skillfish-governor/config.toml
```

Cambia:

```toml
frequency = 2000
```

por ejemplo a:

```toml
frequency = 1800
```

---

## 📄 Créditos

* **Automatización y fixes GCC15 / LLVM21:** eabarriosTGC
* **Governor en Rust:** Magnap
* **Parches originales:** Comunidad BC-250

---

## 📜 Licencia

MIT License

```

---

```
