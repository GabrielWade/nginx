#!/bin/bash
# Script executado quando um stream é interrompido

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

# Marcar este stream como offline
rm -f "$WORK_DIR/${STREAM_NAME}_online"
errcho "Stream $STREAM_NAME está offline"

# Verificar se este era o stream ativo
if [[ -f $ACTIVE_STREAM_FILE ]]; then
    ACTIVE_STREAM=$(cat $ACTIVE_STREAM_FILE)
    
    if [[ "$ACTIVE_STREAM" == "$STREAM_NAME" ]]; then
        errcho "O stream ativo foi interrompido. Buscando alternativa..."
        check_and_switch_stream
    fi
else
    # Verificar se há algum outro stream que podemos usar
    check_and_switch_stream
fi