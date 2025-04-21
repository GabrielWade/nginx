#!/bin/bash
# O arquivo para reproduzir quando o stream estiver offline
offfi="/videos/fallback-video.mp4"
# String aleatória para ser sua chave de stream para o streamRIP
secret="sua_chave_secreta_aqui"
# O endpoint RTMP da Twitch
rtmpe="rtmp://live.twitch.tv/app/live_109642232_JAxuDf5WjFEvhOsAxygozTjFSvTlS3"
# O stream de ingestão RTMP, não precisa alterar
rtmpi="rtmp://127.0.0.1/live/$secret"
###############
# Não alterar #
###############
wd=/tmp/streamrip
pfi=$wd/streamrip
offpidfi=$wd/offline_pid
onpidfi=$wd/online_pid
offlo=$wd/offline_lock
onlo=$wd/online_lock