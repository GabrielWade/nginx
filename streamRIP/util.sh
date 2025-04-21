#!/bin/bash
# Funções utilitárias para o streamRIP

# Função para log de erro
errcho() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $@" >&2
}

# Inicializa o diretório de trabalho e pipe
init_workspace() {
    # Criar diretório de trabalho se não existir
    if [[ ! -d $WORK_DIR ]]; then
        errcho "Criando diretório de trabalho..."
        mkdir -p $WORK_DIR
    fi
    
    # Criar pipe se não existir
    if [[ ! -p $PIPE_FILE ]]; then
        errcho "Criando arquivo pipe..."
        mkfifo $PIPE_FILE
    fi
    
    # Verificar se já existe um stream ativo
    if [[ -f $ACTIVE_STREAM_FILE ]]; then
        CURRENT_STREAM=$(cat $ACTIVE_STREAM_FILE)
        errcho "Stream ativo encontrado: $CURRENT_STREAM"
    else
        errcho "Nenhum stream ativo encontrado"
    fi
}

# Obter o stream com maior prioridade atualmente online
get_highest_priority_stream() {
    local highest_priority=999
    local highest_stream=""
    
    for stream in "${STREAMS[@]}"; do
        if [[ -f "$WORK_DIR/${stream}_online" ]]; then
            if [[ ${STREAM_PRIORITY[$stream]} -lt $highest_priority ]]; then
                highest_priority=${STREAM_PRIORITY[$stream]}
                highest_stream=$stream
            fi
        fi
    done
    
    echo "$highest_stream"
}

# Iniciar um stream específico para a saída
start_stream() {
    local stream_name=$1
    local rtmp_input="rtmp://127.0.0.1/live/$stream_name"
    
    # Adquirir lock
    exec 200>$LOCK_FILE
    flock -x 200
    
    # Parar qualquer stream atual
    stop_active_stream
    
    # Marcar este stream como ativo
    echo "$stream_name" > $ACTIVE_STREAM_FILE
    
    # Iniciar FFmpeg para este stream
    errcho "Iniciando stream: $stream_name"
    ffmpeg -loglevel warning -i "$rtmp_input" -c copy -f flv $TWITCH_OUTPUT &
    
    # Salvar PID
    local pid=$!
    echo $pid > $ACTIVE_PID_FILE
    errcho "Stream iniciado com PID: $pid"
    
    # Liberar lock
    flock -u 200
    
    return 0
}

# Parar o stream ativo
stop_active_stream() {
    if [[ -f $ACTIVE_PID_FILE ]]; then
        local pid=$(cat $ACTIVE_PID_FILE)
        errcho "Parando stream ativo (PID: $pid)..."
        kill $pid 2>/dev/null || true
        rm -f $ACTIVE_PID_FILE
    fi
    
    if [[ -f $ACTIVE_STREAM_FILE ]]; then
        rm -f $ACTIVE_STREAM_FILE
    fi
}

# Iniciar o stream de fallback
start_fallback() {
    # Adquirir lock
    exec 200>$LOCK_FILE
    flock -x 200
    
    # Parar qualquer stream atual
    stop_active_stream
    
    # Iniciar fallback
    errcho "Iniciando stream de fallback..."
    ffmpeg -loglevel warning -stream_loop -1 -re -i $FALLBACK_VIDEO -c copy -f flv $TWITCH_OUTPUT &
    
    # Salvar PID
    local pid=$!
    echo $pid > $FALLBACK_PID_FILE
    errcho "Fallback iniciado com PID: $pid"
    
    # Liberar lock
    flock -u 200
    
    return 0
}

# Parar o fallback
stop_fallback() {
    if [[ -f $FALLBACK_PID_FILE ]]; then
        local pid=$(cat $FALLBACK_PID_FILE)
        errcho "Parando fallback (PID: $pid)..."
        kill $pid 2>/dev/null || true
        rm -f $FALLBACK_PID_FILE
    fi
}

# Verificar se deve mudar para outro stream
check_and_switch_stream() {
    # Adquirir lock
    exec 200>$LOCK_FILE
    flock -x 200
    
    local highest_stream=$(get_highest_priority_stream)
    
    if [[ -z "$highest_stream" ]]; then
        # Nenhum stream disponível, iniciar fallback se não estiver rodando
        if [[ ! -f $FALLBACK_PID_FILE ]]; then
            start_fallback
        fi
    else
        # Verificar se o stream atual é o de maior prioridade
        if [[ -f $ACTIVE_STREAM_FILE ]]; then
            local current_stream=$(cat $ACTIVE_STREAM_FILE)
            
            if [[ "$current_stream" != "$highest_stream" ]]; then
                # Mudar para o stream de maior prioridade
                start_stream "$highest_stream"
            fi
        else
            # Nenhum stream ativo, iniciar o de maior prioridade
            start_stream "$highest_stream"
        fi
    fi
    
    # Liberar lock
    flock -u 200
}