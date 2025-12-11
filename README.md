# AMD BC-250 Ultimate Setup para Arch Linux & Manjaro

> **Estado:** Activo y Actualizado (Diciembre 2025)  
> **Soporta:** Arch Linux, Manjaro, EndeavourOS.

Script automatizado para compilar e instalar un entorno estable para la placa **AMD BC-250 (Cyan Skillfish)**, solucionando los problemas de pantalla negra, congelamientos y falta de aceleración gráfica en kernels recientes.

---

## 🛑 El Problema (¿Por qué existe este repo?)

Si has intentado usar Arch Linux recientemente en la BC-250, habrás notado:
1.  **Pantalla negra al arrancar:** Los kernels recientes (6.12+, 6.17+) tienen regresiones en el módulo `amdgpu` para este hardware exótico.
2.  **Sin aceleración:** `glxinfo` muestra `llvmpipe` en lugar de la GPU RDNA2.
3.  **Crash en actualizaciones:** Un `pacman -Syu` puede romper el sistema inesperadamente.

Los métodos antiguos (habilitar repos `testing` o esperar a Mesa upstream) **ya no son seguros** debido a la inestabilidad del soporte "bleeding edge" para esta placa minera convertida.

## 🧠 La Solución Técnica

A diferencia de otros scripts que confían en repositorios externos o versiones inestables, este repositorio adopta un enfoque de **"Estabilidad Congelada"**:

1.  **Kernel LTS Custom:** Compilamos una versión parcheada del Kernel LTS (6.6.x) específicamente configurada para inicializar correctamente el `amdgpu` de la Cyan Skillfish.
2.  **Mesa Parcheado:** Compilamos la última versión estable de Mesa (24.3.x) con el parche `navi10-range` aplicado, asegurando soporte Vulkan y OpenGL completo.
3.  **Governor Fix:** Instalamos un servicio systemd nativo que fuerza el perfil de energía correcto al inicio, evitando el bajo rendimiento o crashes por gestión de energía.
4.  **Protección contra Updates:** El script ofrece bloquear estos paquetes en `pacman.conf` para que Arch pueda actualizarse sin romper tus drivers gráficos.

---

## 🚀 Instalación

### Requisitos Previos
*   Una instalación limpia (o funcional) de Arch Linux o Manjaro.
*   Conexión a internet.
*   **Paciencia:** Compilar el Kernel y Mesa puede tardar entre **40 minutos y 2 horas** dependiendo de tu CPU, pero es un proceso único que garantiza estabilidad.

### Pasos

1.  **Instalar Git:**
    ```bash
    sudo pacman -S git base-devel
    ```

2.  **Clonar el repositorio:**
    ```bash
    git clone https://github.com/eabarriosTGC/BC250--ARCH.git
    cd BC250--ARCH
    ```

3.  **Dar permisos y ejecutar:**
    ```bash
    chmod +x install.sh
    ./install.sh
    ```

4.  **Seguir las instrucciones en pantalla:**
    *   Se recomienda decir **SÍ (y)** a todas las opciones (Kernel, Mesa y Bloqueo de paquetes).

5.  **Reiniciar:**
    *   Al reiniciar, asegúrate de seleccionar **"Linux LTS AMD BC-250"** en el menú de GRUB/Systemd-boot.

---

## 📊 Verificación

Una vez reiniciado, ejecuta estos comandos para verificar que todo funciona:

```bash
# Debe mostrar kernel 6.6.x-bc250
uname -r 

# Debe mostrar "AMD Radeon Graphics" o "Cyan Skillfish" (NO llvmpipe)
glxinfo | grep "OpenGL renderer"

# Debe mostrar tu GPU correctamente
vulkaninfo | grep deviceName
