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

![Image alt](https://github.com/eabarriosTGC/BC250--ARCH/blob/17e3dc21465d43af5f1cf50b777fd111dba8e534/Captura%20desde%202025-06-12%2008-59-12.png)
![Image alt](https://github.com/eabarriosTGC/BC250--ARCH/blob/eadb312d559b32ba5732df1996ac99d7360f61c9/Captura%20desde%202025-06-12%2003-03-40.png)

## 📚 Fuente principal

Gran parte de esta configuración se basa en el siguiente repositorio:
🔗 [mothenjoyer69/bc250-documentation](https://github.com/mothenjoyer69/bc250-documentation)

---

## 📄 Licencia

Este proyecto está licenciado bajo la **MIT License**.

---
