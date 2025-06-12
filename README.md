# Configuración y Optimización para la Placa **AMD BC-250** en **Arch Linux**

> Específicamente probado en Arch con entorno de escritorio **GNOME**.
## 🧠 ¿Cómo funciona este script? La Diferencia Técnica

Quizás hayas visto otros scripts para la BC-250, como el popular para Fedora. Es importante entender la diferencia técnica en el enfoque, ya que esto resalta una de las ventajas de usar una distribución *rolling release* como Arch Linux.

### El Desafío: El Soporte en Mesa

El principal obstáculo para hacer funcionar la GPU de la BC-250 es que su identificador de hardware (PCI ID) no era reconocido por las versiones antiguas de **Mesa**, la librería gráfica esencial en Linux.

Para solucionarlo, la comunidad creó un **parche** que simplemente añade el ID de la BC-250 a la lista de GPUs soportadas por los drivers `amdgpu` (RADV para Vulkan y Radeonsi para OpenGL). Este parche fue oficialmente integrado en el código fuente de **Mesa a partir de la versión 25.1**.

### El Enfoque de Fedora vs. El Enfoque de Arch Linux

Aquí radica la diferencia clave:

| Característica | Enfoque Fedora (usando COPR) | Enfoque Arch Linux (este script) |
| :--- | :--- | :--- |
| **Fuente de Mesa** | Un repositorio de terceros (COPR) que contiene una versión de Mesa **parcheada manualmente**. | El repositorio oficial `[testing]` de Arch Linux. |
| **Naturaleza del Soporte** | **Externo:** Se instala una versión de Mesa modificada por la comunidad, ya que la versión oficial de Fedora es anterior a la 25.1. | **Nativo (Upstream):** Se instala la versión oficial de Mesa 25.1 (o superior), la cual ya incluye el soporte para la BC-250 "de fábrica". |
| **Analogía** | Es como darle al portero una invitación escrita a mano para que te deje entrar. | Tu nombre ya estaba impreso en la lista oficial de invitados. |

En resumen, este script para Arch Linux **no necesita aplicar parches externos**. Simplemente habilita el repositorio `[testing]` para acceder a la última versión oficial de Mesa, que ya contiene el soporte necesario. Esto resulta en una instalación más limpia, estándar y sostenible a largo plazo. Una vez que Mesa 25.1 llegue a los repositorios estables de Arch, ni siquiera será necesario el repositorio `[testing]`.


---

## ⚠️ Aviso Importante

* Se recomienda usar la **versión LTS del kernel**, ya que las versiones más recientes (incluyendo **Zen**) presentan problemas como **congelamiento de pantalla**.
* Durante la instalación de Arch, **ELEGIR LOS CONTROLADORES GRAFICOS OPEN SOURCE DE AMD `**.
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
