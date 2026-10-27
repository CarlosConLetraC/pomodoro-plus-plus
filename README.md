# Pomodoro Plus Plus

Aplicación de escritorio modular basada en Electron para la gestión del tiempo y productividad, diseñada con un entorno de desarrollo portable y automatizado para Linux.

## Sistemas Operativos Compatibles (Linux)

El framework de staging bootstrap soporta nativamente las siguientes distribuciones:

* **<OS>** (Entorno principal)
* **Arch Linux**
* **Ubuntu**

---

## 1. Instalación y Staging Bootstrap (Configuración y Dependencias)

Para desplegar y configurar todo el proyecto desde cero utilizando exclusivamente el conjunto de scripts de orquestación:

1. **Clonar el repositorio**:
```bash
git clone https://github.com/CarlosConLetraC/pomodoro-plus-plus.git
cd pomodoro-plus-plus
```

2. **Ejecutar el orquestador principal (`setup.sh`)**:
Este script detecta tu distribución compatible, lee los parámetros globales desde `install/requirements.conf`, configura las herramientas del sistema operativo mediante `pacman`|`apt`, instala Node.js de forma aislada en `.node_env`, descarga los binarios de Electron y prepara las dependencias de empaquetado.
```bash
./setup.sh
```

---

## 2. Desarrollo Local y Pruebas (`init.sh`)

*Nota importante:* El script `init.sh` **no** realiza tareas de instalación ni compilación. Únicamente se utiliza una vez que el proyecto ya se encuentra configurado para levantar la aplicación en modo de desarrollo local, inyectando las rutas del `PATH` y ejecutando Electron directamente sobre los fuentes modulares de `src/`.

Para probar la aplicación en tu entorno gráfico:
```bash
./init.sh
```

---

## 3. Compilación del Entregable Final (`build.sh`)

Una vez realizadas las pruebas necesarias, para empaquetar la aplicación en un formato portable autónomo (sin dependencias de FUSE) listo para producción y GitHub Releases:
```bash
./build.sh
```
Esto generará la estructura compilada y el paquete comprimido final dentro de la carpeta `dist/`.

---

## 4. Descripción Detallada de cada Script (`.sh`)

* **`setup.sh`**: Orquestador principal del bootstrap. Detecta el sistema operativo del host, resuelve el directorio de etapas correspondiente y ejecuta secuencialmente los scripts numéricos de configuración.


* **`init.sh`**: Lanzador de pruebas y desarrollo local. Carga el entorno aislado de Node (`.node_env/bin`) e inicia la aplicación Electron apuntando a los archivos fuente modulares, requiriendo que el proyecto haya sido previamente inicializado.


* **`build.sh`**: Script de compilación y empaquetado. Utiliza `electron-builder` para generar la distribución portable (`dir`) y empaqueta el resultado en un archivo `.tar.gz` optimizado.
* **`common.sh`**: Librería central de funciones compartidas. Proporciona registro con marcas de tiempo (`prettyprint`), detección automática del sistema operativo (`get_os_version`), resolución de rutas y utilidades para contenedores Podman (`podmanbuild`, `podmanrun`).


* **`pods.sh`**: Utilidad de contenedores. Limpia contenedores detenidos y reconstruye de manera limpia todas las imágenes de Podman a partir de los archivos `.dockerfile` ubicados en `dockers/`.

## 4.1. Staging Bootstrap

* **`install/<OS>/<VERSION>/00/base.sh`**: Script de la etapa inicial. Configura los parámetros de `pacman.conf` para entornos rootless y asegura la instalación de herramientas compartidas esenciales como `unzip` y `curl`.
* **`install/<OS>/<VERSION>/01/chromium.sh`**: Descarga chromium y lo compila desde código fuente (versión específica en `install/requirements.conf`).
* **`install/<OS>/<VERSION>/01/node.sh`**: Descarga nodejs, npm y npx y configura dependencias temporalmente (versión específica en `install/requirements.conf`)
* **`install/<OS>/<VERSION>/02/electron.sh`**: Script de la etapa de Electron. Instala las dependencias gráficas necesarias mediante `pacman`, aprovisiona Electron localmente, valida de forma estricta la estructura modular en `src/` (`index.js`, `index.html`, etc.) y configura `electron-builder`.
