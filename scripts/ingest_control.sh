#!/bin/bash

# Diretório para armazenar o estado dos ingest points
INGEST_STATE_DIR="/tmp/ingest_state"
mkdir -p $INGEST_STATE_DIR

# Função para verificar quais ingest points estão ativos
check_active_ingests() {
    active_ingests=()
    
    if [ -f "$INGEST_STATE_DIR/ingest1.active" ]; then
        active_ingests+=("ingest1")
    fi
    
    if [ -f "$INGEST_STATE_DIR/ingest2.active" ]; then
        active_ingests+=("ingest2")
    fi
    
    # Você pode adicionar mais ingest points aqui
    
    echo "${active_ingests[@]}"
}

# Função para ativar um ingest
activate_ingest() {
    ingest_name=$1
    echo "$(date) - Ativando ingest: $ingest_name" >> /var/log/nginx/ingest_control.log
    touch "$INGEST_STATE_DIR/$ingest_name.active"
}

# Função para desativar um ingest
deactivate_ingest() {
    ingest_name=$1
    echo "$(date) - Desativando ingest: $ingest_name" >> /var/log/nginx/ingest_control.log
    rm -f "$INGEST_STATE_DIR/$ingest_name.active"
}

# Função para verificar e ativar o fallback se necessário
check_fallback() {
    active_ingests=($(check_active_ingests))
    
    if [ ${#active_ingests[@]} -eq 0 ]; then
        echo "$(date) - Nenhum ingest ativo. Ativando fallback." >> /var/log/nginx/ingest_control.log
        # Ative o fallback aqui
        # Por exemplo: iniciando um streaming de um arquivo de fallback
        if [ ! -f "$INGEST_STATE_DIR/fallback.active" ]; then
            # Iniciar o streaming de fallback
            ffmpeg -re -i /opt/fallback/video.mp4 -c copy -f flv rtmp://localhost/fallback/stream &
            echo $! > "$INGEST_STATE_DIR/fallback.pid"
            touch "$INGEST_STATE_DIR/fallback.active"
        fi
    else
        echo "$(date) - Ingest ativo: ${active_ingests[0]}. Desativando fallback." >> /var/log/nginx/ingest_control.log
        # Desative o fallback se estiver ativo
        if [ -f "$INGEST_STATE_DIR/fallback.active" ]; then
            if [ -f "$INGEST_STATE_DIR/fallback.pid" ]; then
                kill $(cat "$INGEST_STATE_DIR/fallback.pid")
                rm "$INGEST_STATE_DIR/fallback.pid"
            fi
            rm "$INGEST_STATE_DIR/fallback.active"
        fi
    fi
}

# Loop principal para monitoramento contínuo
monitor_loop() {
    while true; do
        check_fallback
        sleep 5
    done
}

# Iniciar o loop de monitoramento em segundo plano
monitor_loop &

# Configurando o NGINX para controle via API HTTP
# O NGINX vai chamar este script com parâmetros específicos quando eventos ocorrerem
case "$1" in
    "publish_monitor")
        # Quando um stream começa em um ingest point de monitoramento
        ingest_name=$(echo $2 | cut -d'/' -f2)
        activate_ingest $ingest_name
        ;;
    "publish_monitor_done")
        # Quando um stream termina em um ingest point de monitoramento
        ingest_name=$(echo $2 | cut -d'/' -f2)
        deactivate_ingest $ingest_name
        ;;
    *)
        # Comando não reconhecido
        echo "Comando não reconhecido: $1"
        ;;
esac

exit 0