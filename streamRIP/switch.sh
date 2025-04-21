#!/bin/bash
# Script para alternar manualmente entre streams

# Obter o diretório atual
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

# Carregar configurações e utilitários
. "$DIR/config.sh"
. "$DIR/util.sh"

# Verificar argumentos
if [ $# -lt 1 ]; then
    echo "Uso: $0 <nome_do_stream>"
    echo "Streams disponíveis:"
    for stream in "${STREAMS[@]}"; do
        echo "  - $stream"
    done
    echo "  - fallback (para iniciar o vídeo de fallback)"
    exit 1
fi

STREAM_NAME="$1"

# Inicializar workspace
init_workspace

# Verificar se o stream solicitado existe
if [[ "$STREAM_NAME" == "fallback" ]]; then
    # Iniciar fallback
    stop_active_stream
    start_fallback
    exit 0
fi

# Verificar se o stream está na lista de streams conhecidos
FOUND=0
for stream in "${STREAMS[@]}"; do
    if [[ "$stream" == "$STREAM_NAME" ]]; then
        FOUND=1
        break
    fi
done

if [[ $FOUND -eq 0 ]]; then
    echo "Erro: Stream '$STREAM_NAME' não reconhecido."
    echo "Streams disponíveis:"
    for stream in "${STREAMS[@]}"; do
        echo "  - $stream"
    done
    echo "  - fallback (para iniciar o vídeo de fallback)"
    exit 1
fi

# Verificar se o stream solicitado está online
if [[ ! -f "$WORK_DIR/${STREAM_NAME}_online" ]]; then
    echo "Aviso: O stream '$STREAM_NAME' não está online."
    echo "Streams online:"
    for stream in "${STREAMS[@]}"; do
        if [[ -f "$WORK_DIR/${stream}_online" ]]; then
            echo "  - $stream"
        fi
    done
    
    # Perguntar se deve continuar mesmo assim
    read -p "Forçar troca para este stream mesmo assim? (s/n) " FORCE
    if [[ "$FORCE" != "s" ]]; then
        exit 1
    fi
    
    # Se forçar, criar um arquivo fake de online
    touch "$WORK_DIR/${STREAM_NAME}_online"
fi

# Alterar a prioridade temporariamente para este stream ser o mais alto
for stream in "${STREAMS[@]}"; do
    if [[ "$stream" == "$STREAM_NAME" ]]; then
        STREAM_PRIORITY[$stream]=0  # Prioridade máxima
    else
        # Restaurar prioridade original ou aumentar
        STREAM_PRIORITY[$stream]=${STREAM_PRIORITY[$stream]}
    fi
done

# Iniciar o stream solicitado
start_stream "$STREAM_NAME"
echo "Stream alterado para: $STREAM_NAME"