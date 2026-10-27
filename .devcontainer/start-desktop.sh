#!/usr/bin/env bash
set -euo pipefail

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
fi

workspace_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

case "${ID:-}" in
  ubuntu|debian)
    ;;
  *)
    echo "Unsupported container image: ${PRETTY_NAME:-unknown}. Rebuild this workspace inside the Ubuntu dev container configured in .devcontainer/devcontainer.json." >&2
    exit 1
    ;;
esac

system_bus_socket="/run/dbus/system_bus_socket"

run_root() {
  if command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    "$@"
  fi
}

dbus_cmd() {
  if command -v dbus-send >/dev/null 2>&1; then
    dbus-send --system --type=method_call --print-reply --dest=org.freedesktop.DBus / org.freedesktop.DBus.ListNames
  fi
}

system_bus_is_running() {
  [[ -S "$system_bus_socket" ]] \
    && dbus_cmd >/dev/null 2>&1
}

if command -v dbus-daemon >/dev/null 2>&1; then
  if ! system_bus_is_running; then
    run_root rm -f "$system_bus_socket" /run/dbus/pid 2>/dev/null || true
    if getent passwd messagebus >/dev/null 2>&1; then
      run_root install -d -o messagebus -g messagebus /run/dbus
    else
      run_root install -d -m 755 /run/dbus
    fi
    run_root dbus-daemon --system --fork
  fi
else
  echo "D-Bus is not installed in this container. Rebuild the dev container with the Ubuntu desktop image." >&2
  exit 1
fi

for attempt in {1..10}; do
  system_bus_is_running && break
  sleep 1
done

if ! system_bus_is_running; then
  echo "D-Bus system bus is not responding at $system_bus_socket" >&2
  exit 1
fi

vnc_dir="$HOME/.vnc"
mkdir -p "$vnc_dir"

if [[ ! -s "$vnc_dir/passwd" ]]; then
  printf '%s' "${VNC_PASSWORD:-vscode}" | vncpasswd -f > "$vnc_dir/passwd"
  chmod 600 "$vnc_dir/passwd"
fi

cat > "$vnc_dir/xstartup" <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-launch --exit-with-session startxfce4
EOF
chmod +x "$vnc_dir/xstartup"

display_lock="/tmp/.X1-lock"
display_socket="/tmp/.X11-unix/X1"
if [[ -f "$display_lock" ]]; then
  lock_pid="$(tr -dc '0-9' < "$display_lock")"
  if [[ -n "$lock_pid" ]] && ! kill -0 "$lock_pid" 2>/dev/null; then
    rm -f "$display_lock" "$display_socket"
  fi
fi

if ! command -v tigervncserver >/dev/null 2>&1; then
  echo "TigerVNC is not installed. Rebuild the dev container from the Ubuntu-based desktop image." >&2
  exit 1
fi

vnc_backend_is_running() {
  timeout 2 bash -c '
    exec 3<>/dev/tcp/127.0.0.1/5901
    IFS= read -r -N 12 banner <&3
    [[ "$banner" == RFB* ]]
  ' >/dev/null 2>&1
}

if ! pgrep -f '[X]tigervnc.*:1' >/dev/null; then
  tigervncserver :1 \
    -geometry 1600x900 \
    -depth 24 \
    -localhost yes \
    -rfbport 5901 \
    -SecurityTypes VncAuth \
    -passwd "$vnc_dir/passwd" \
    -xstartup "$vnc_dir/xstartup"
fi

compositor_configured=false
for attempt in {1..30}; do
  if DISPLAY=:1 xfconf-query -c xfwm4 -p /general/use_compositing -s false >/dev/null 2>&1; then
    compositor_configured=true
    break
  fi
  sleep 1
done

if [[ "$compositor_configured" != true ]]; then
  echo "Could not disable XFCE compositing for the TigerVNC desktop" >&2
  exit 1
fi

if [[ -x /usr/share/novnc/utils/novnc_proxy ]]; then
  if ! pgrep -f '[n]ovnc_proxy.*6080' >/dev/null; then
    nohup /usr/share/novnc/utils/novnc_proxy \
      --listen 6080 \
      --vnc localhost:5901 \
      > "$HOME/.novnc.log" 2>&1 &
  fi
else
  echo "noVNC is not installed. Rebuild the container with the desktop stack installed." >&2
  exit 1
fi

transfer_dir="$HOME/iPad-Transfers"
if mountpoint -q /mnt/device-storage; then
  transfer_dir="/mnt/device-storage/iPad-Transfers"
fi
if ! mkdir -p "$transfer_dir"; then
  echo "Could not create the iPad transfer directory: $transfer_dir" >&2
  exit 1
fi
if [[ ! -w "$transfer_dir" ]]; then
  echo "The iPad transfer directory is not writable: $transfer_dir" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 is required for the iPad file-transfer page." >&2
  exit 1
fi

if ! curl --fail --silent http://127.0.0.1:8080/health >/dev/null; then
  nohup python3 "$workspace_dir/.devcontainer/ipad-transfer.py" \
    --directory "$transfer_dir" \
    --port 8080 \
    > "$HOME/.ipad-transfer.log" 2>&1 &
fi

transfer_ready=false
for attempt in {1..10}; do
  if curl --fail --silent http://127.0.0.1:8080/health >/dev/null; then
    transfer_ready=true
    break
  fi
  sleep 1
done

if [[ "$transfer_ready" != true ]]; then
  if [[ -f "$HOME/.ipad-transfer.log" ]]; then
    printf '%s\n' "--- $HOME/.ipad-transfer.log ---" >&2
    tail -n 80 "$HOME/.ipad-transfer.log" >&2
  fi
  echo "The iPad file-transfer page did not become ready on port 8080" >&2
  exit 1
fi

proxy_host="184.170.249.65"
proxy_port="4145"
proxy_url="socks5h://${proxy_host}:${proxy_port}"
mkdir -p "$HOME/.config/environment.d" "$HOME/.local/share/applications"
cat > "$HOME/.config/environment.d/vus-proxy.conf" <<EOF
http_proxy=${proxy_url}
https_proxy=${proxy_url}
HTTP_PROXY=${proxy_url}
HTTPS_PROXY=${proxy_url}
NO_PROXY=localhost,127.0.0.1,::1
MOZ_DISABLE_CONTENT_SANDBOX=1
MOZ_DISABLE_GMP_SANDBOX=1
EOF

cat > "$HOME/.local/share/applications/vus-firefox.desktop" <<EOF
[Desktop Entry]
Name=VUS Firefox (Proxy)
Comment=Firefox configured for the trusted SOCKS5 proxy
Exec=env MOZ_DISABLE_CONTENT_SANDBOX=1 MOZ_DISABLE_GMP_SANDBOX=1 /usr/local/bin/firefox --new-instance --no-remote --proxy-server=${proxy_url} --ignore-certificate-errors %u
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOF
chmod +x "$HOME/.local/share/applications/vus-firefox.desktop"

for attempt in {1..30}; do
  if curl --fail --silent http://127.0.0.1:6080/vnc.html >/dev/null \
    && vnc_backend_is_running; then
    exit 0
  fi
  sleep 1
done

for log in "$vnc_dir"/*.log "$HOME/.novnc.log"; do
  if [[ -f "$log" ]]; then
    printf '%s\n' "--- $log ---" >&2
    tail -n 80 "$log" >&2
  fi
done
echo "The noVNC page or TigerVNC backend did not become ready" >&2
exit 1