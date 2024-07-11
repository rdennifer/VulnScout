#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}\n
__     __     _       ____                  _   
\ \   / /   _| |_ __ / ___|  ___ ___  _   _| |_ 
 \ \ / / | | | | '_ \\___ \ / __/ _ \| | | | __|
  \ V /| |_| | | | | |___) | (_| (_) | |_| | |_ 
   \_/  \__,_|_|_| |_|____/ \___\___/ \__,_|\__|  v1.0                                              
                                                                                     
Create By: hades.ethical.hacking | Team Offsec Peru \n${NC}"

# Función para realizar una solicitud HTTP y obtener solo las cabeceras
conector() {
    URL=$1
    USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"
    curl -s -A "$USER_AGENT" -I "$URL"
}

# Función para obtener el contenido de una URL
obtener_contenido() {
    URL=$1
    USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"
    curl -s -A "$USER_AGENT" "$URL"
}

# Función para limpiar y filtrar URLs únicas
limpiar_urls() {
    INPUT_FILE=$1
    OUTPUT_FILE=$2
    sort -u "$INPUT_FILE" > "$OUTPUT_FILE"
}

# Función para verificar e instalar/actualizar Nuclei
verificar_nuclei() {
    if ! command -v nuclei &> /dev/null; then
        echo -e "${YELLOW}Nuclei no está instalado. Instalando...${NC}"
        go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
        export PATH=$PATH:$(go env GOPATH)/bin
    else
        echo -e "${GREEN}Nuclei ya está instalado. Actualizando...${NC}"
        nuclei -update-templates
    fi
}

# Función para ejecutar Nuclei
ejecutar_nuclei() {
    INPUT_FILE=$1
    OUTPUT_FILE="nuclei_report.txt"
    echo "Ejecutando Nuclei en las URLs guardadas en $INPUT_FILE..."
    nuclei -l "$INPUT_FILE" -o "$OUTPUT_FILE" -silent -timeout 10
    echo "Informe de Nuclei guardado en $OUTPUT_FILE"
}

# Función principal
principal() {
    EXCLUIR="jpg,png,jpeg,doc,pdf,xls,ppt,mp3,mp4,zip,rar,gif,bmp,tiff,wav,js,css"
    
    read -p "Ingrese el dominio a evaluar: " DOMINIO

    URL="https://web.archive.org/cdx/search/cdx?url=${DOMINIO}/*&output=txt&fl=original&collapse=urlkey&page=/"

    RESPUESTA=$(obtener_contenido "$URL")

    if [ -z "$RESPUESTA" ]; then
        echo "No se pudo obtener datos de Wayback Machine."
        exit 1
    fi

    IFS=',' read -r -a LISTA_NEGRA <<< "$EXCLUIR"
    echo -e "${RED}[!] Las URL que contienen estas extensiones se excluirán de los resultados: ${LISTA_NEGRA[*]}${NC}\n"

    echo "Cabeceras válidas:"
    conector "http://${DOMINIO}"

    URLS_VALIDAS=()
    URLS_IMPRIMIDAS=()
    CABECERAS_VISTAS=()

    for URL in $RESPUESTA; do
        EXCLUIR_URL=false
        for EXT in "${LISTA_NEGRA[@]}"; do
            if [[ $URL == *"$EXT"* ]]; then
                EXCLUIR_URL=true
                break
            fi
        done

        if [ "$EXCLUIR_URL" = false ]; then
            URL_MODIFICADA=$(echo "$URL" | sed 's/?[^"]*//')

            if [[ ! " ${URLS_IMPRIMIDAS[@]} " =~ " ${URL_MODIFICADA} " ]]; then
                URLS_IMPRIMIDAS+=("$URL_MODIFICADA")
                RESPUESTA=$(curl -s -I "$URL_MODIFICADA")
                STATUS_CODE=$(echo "$RESPUESTA" | grep HTTP | awk '{print $2}')
                HEADERS=$(echo "$RESPUESTA" | grep -v "^$")
                HEADERS_HASH=$(echo "$HEADERS" | md5sum | awk '{print $1}')
                case $STATUS_CODE in
                    200) COLOR=$GREEN;;
                    3*) COLOR=$BLUE;;
                    4*) COLOR=$YELLOW;;
                    5*) COLOR=$RED;;
                    *) COLOR=$NC; STATUS_CODE="UNKNOWN";;
                esac
                if [[ "$STATUS_CODE" == "200" || "$STATUS_CODE" == "301" || "$STATUS_CODE" == "302" || "$STATUS_CODE" == "401" || "$STATUS_CODE" == "403" || "$STATUS_CODE" == "500" || "$STATUS_CODE" == "UNKNOWN" ]]; then
                    URLS_VALIDAS+=("$URL_MODIFICADA")
                    echo -e "[${GREEN}+${NC}] Código de estado: ${COLOR}$STATUS_CODE${NC} - $URL_MODIFICADA"
                    if [[ ! " ${CABECERAS_VISTAS[@]} " =~ " ${HEADERS_HASH} " ]]; then
                        CABECERAS_VISTAS+=("$HEADERS_HASH")
                        echo -e "${BLUE}Headers:${NC}\n$HEADERS"
                    fi
                    if [ ! -z "$SALIDA" ]; then
                        echo "[+] Código de estado: $STATUS_CODE - $URL_MODIFICADA" >> "$SALIDA"
                        if [[ ! " ${CABECERAS_VISTAS[@]} " =~ " ${HEADERS_HASH} " ]]; then
                            echo "$HEADERS" >> "$SALIDA"
                        fi
                    fi
                fi
            fi
        fi
    done

    if [ -z "$SALIDA" ]; then
        read -p "¿Deseas guardar el resultado en un archivo? (s/n): " GUARDAR
        if [[ "$GUARDAR" =~ ^[sS]$ ]]; then
            SALIDA="resultados.txt"
            echo "Guardando resultados en $SALIDA..."
            for URL in "${URLS_VALIDAS[@]}"; do
                echo "$URL" >> "$SALIDA"
            done
            echo "Resultados guardados en $SALIDA"
            limpiar_urls "$SALIDA" "urls_limpias.txt"
            grep -E '^http://' urls_limpias.txt > urls_http.txt
            grep -E '^https://' urls_limpias.txt > urls_https.txt
            verificar_nuclei
            ejecutar_nuclei "urls_http.txt"
            ejecutar_nuclei "urls_https.txt"
        fi
    fi
}

# Ejecutar la función principal
principal "$@"
