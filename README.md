# Configuración y Optimización para la Placa **AMD BC-250** en **Arch Linux**

> Específicamente probado en Arch con entorno de escritorio **GNOME**.

---

## ⚠️ Aviso Importante

* Se recomienda usar la **versión LTS del kernel**, ya que las versiones más recientes (incluyendo **Zen**) presentan problemas como **congelamiento de pantalla**.
* Durante la instalación de Arch, **habilita el repositorio `multilib`**.

---

## 🚀 Pasos de Instalación

1. Instala `git` si no lo tienes:

   ```bash
   sudo pacman -S git
   ```

2. Clona este repositorio:

   ```bash
   git clone https://github.com/eabarriosTGC/BC250--ARCH
   ```

3. Da permisos de ejecución al script de configuración:

   ```bash
   cd /BC250--ARCH
   sudo chmod +x ./Arch-setup.sh
   ```

4. Ejecuta el script:

   ```bash
   sudo ./Arch-setup.sh
   ```

5. Confirma la instalación y ¡listo!

---



## 📚 Fuente principal

Gran parte de esta configuración se basa en el siguiente repositorio:
🔗 [mothenjoyer69/bc250-documentation](https://github.com/mothenjoyer69/bc250-documentation)

---

## 📄 Licencia

Este proyecto está licenciado bajo la **MIT License**.

---
