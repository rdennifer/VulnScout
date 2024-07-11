# VulnScout V1.0
VulnScout es un script en Bash diseñado para analizar y obtener información de URLs archivadas en Wayback Machine y realizar un análisis de vulnerabilidades utilizando Nuclei.
## Características

- **Obtención de cabeceras HTTP**: El script recupera las cabeceras HTTP de URLs archivadas en Wayback Machine, lo que permite obtener información valiosa sobre el estado y configuración de los servidores en el pasado.
- **Filtrado de URLs**: Excluye automáticamente las URLs que contienen extensiones de archivos específicas como imágenes, documentos y archivos multimedia, centrándose únicamente en las URLs relevantes para el análisis.
- **Análisis de vulnerabilidades**: Utiliza Nuclei, una poderosa herramienta de análisis de vulnerabilidades, para escanear las URLs filtradas y generar informes detallados sobre posibles vulnerabilidades.
- **Soporte para HTTP y HTTPS**: El script identifica y separa las URLs en HTTP y HTTPS, permitiendo un análisis más detallado y específico para cada tipo de URL.

## Requisitos

- `curl`
- `nuclei`
- `grep`
- `sort`

## Instalación

1. **Clona este repositorio**:
   ```bash
   git clone https://github.com/tu-usuario/vulnscout.git
   cd vulnscout
   chmod +x vulnscout

## Ejecuta el script:
     ./VulnScout.sh
   
![image](https://github.com/user-attachments/assets/371d9160-a8c6-48b6-ba13-7ef7184fae1e)


![image](https://github.com/user-attachments/assets/d538aea5-94c7-479a-81a6-ed2c9e7d1ccf)
