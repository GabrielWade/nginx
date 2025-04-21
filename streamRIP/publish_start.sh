#!/bin/bash
# Script executado quando um stream é publicado

# Obter o diretório atual
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

# Carregar configurações e utilitários
. "$DIR/config.sh"
. "$DIR/util.sh"

# Nome do stream (passado pelo nginx como $1)
STREAM_NAME="$1"

# Inicializar workspace
init_workspace

# Marcar este stream como online
touch "$WORK_DIR/${STREAM_NAME}_online"
errcho "Stream $STREAM_NAME está online"

# Verificar se devemos mudar para este stream com base na prioridade
check_and_switch_stream