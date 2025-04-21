#!/bin/bash
# Script executado quando o NGINX inicia

# Obter o diretório atual
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

# Carregar configurações e utilitários
. "$DIR/config.sh"
. "$DIR/util.sh"

# Inicializar workspace
init_workspace

# Iniciar o stream de fallback
start_fallback

# Manter o script em execução para gerenciar os streams
errcho "NGINX RTMP iniciado e pronto para receber streams"