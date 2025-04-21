FROM tiangolo/nginx-rtmp

# Instalar FFmpeg e outras dependências necessárias
RUN apt-get update && \
    apt-get install -y ffmpeg bash && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*