#!/usr/bin/env bash
set -euo pipefail

while true; do
  if ffmpeg \
    -hide_banner \
    -loglevel warning \
    -f pulse \
    -i browser_audio.monitor \
    -c:a libmp3lame \
    -b:a 128k \
    -f mp3 \
    -content_type audio/mpeg \
    -listen 1 \
    http://127.0.0.1:6081/audio.mp3; then
    echo "The browser audio client disconnected; restarting the stream listener."
  else
    status=$?
    echo "The browser audio stream exited with status $status; retrying."
  fi
  sleep 2
done
