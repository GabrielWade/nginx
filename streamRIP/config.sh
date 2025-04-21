#!/bin/bash
# Configurações gerais para o streamRIP

# O arquivo para reproduzir quando o stream estiver offline
FALLBACK_VIDEO="/videos/fallback-video.mp4"

# String aleatória para ser sua chave de stream
SECRET="sua_chave_secreta_aqui"

# Diretório de trabalho
WORK_DIR="/tmp/streamrip"

# Pipe para o FFmpeg
PIPE_FILE="$WORK_DIR/streamrip"

# Arquivos de controle
ACTIVE_STREAM_FILE="$WORK_DIR/active_stream"
ACTIVE_PID_FILE="$WORK_DIR/active_pid"
FALLBACK_PID_FILE="$WORK_DIR/fallback_pid"
LOCK_FILE="$WORK_DIR/stream_lock"

# Streams disponíveis (adicione mais conforme necessário)
STREAMS=("stream1" "stream2" "stream3" "stream4" "stream5")

# Prioridade padrão dos streams (menor número = maior prioridade)
declare -A STREAM_PRIORITY
STREAM_PRIORITY["stream1"]=1
STREAM_PRIORITY["stream2"]=2
STREAM_PRIORITY["stream3"]=3
STREAM_PRIORITY["stream4"]=4
STREAM_PRIORITY["stream5"]=5

# URL de saída para o aplicativo Twitch
TWITCH_OUTPUT="rtmp://127.0.0.1/twitch/$SECRET"