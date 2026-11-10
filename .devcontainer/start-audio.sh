#!/usr/bin/env bash
set -euo pipefail

workspace_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v pulseaudio >/dev/null 2>&1 || ! command -v pactl >/dev/null 2>&1; then
  echo "PulseAudio is not installed. Rebuild the dev container with the desktop audio packages." >&2
  exit 1
fi

if ! pulseaudio --check >/dev/null 2>&1; then
  pulseaudio --start --exit-idle-time=-1
fi

if ! pactl list short sinks | awk '$2 == "browser_audio" { found = 1 } END { exit !found }'; then
  pactl load-module module-null-sink sink_name=browser_audio sink_properties=device.description=Browser_Audio >/dev/null
fi
pactl set-default-sink browser_audio

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "FFmpeg is not installed. Rebuild the dev container with the desktop audio packages." >&2
  exit 1
fi

if ! curl --fail --silent http://127.0.0.1:6082/health >/dev/null; then
  nohup python3 "$workspace_dir/.devcontainer/audio-receiver.py" \
    --port 6082 \
    --upstream http://127.0.0.1:6081/audio.mp3 \
    > "$HOME/.desktop-audio-receiver.log" 2>&1 &
fi

audio_receiver_ready=false
for attempt in {1..10}; do
  if curl --fail --silent http://127.0.0.1:6082/health >/dev/null; then
    audio_receiver_ready=true
    break
  fi
  sleep 1
done

if [[ "$audio_receiver_ready" != true ]]; then
  if [[ -f "$HOME/.desktop-audio-receiver.log" ]]; then
    printf '%s\n' "--- $HOME/.desktop-audio-receiver.log ---" >&2
    tail -n 80 "$HOME/.desktop-audio-receiver.log" >&2
  fi
  echo "The desktop audio receiver did not become ready on port 6082" >&2
  exit 1
fi

if ! pgrep -f '[s]tream-desktop-audio.sh' >/dev/null; then
  nohup bash "$workspace_dir/.devcontainer/stream-desktop-audio.sh" \
    > "$HOME/.desktop-audio.log" 2>&1 &
fi
