#!/usr/bin/env bash
set -euo pipefail

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

if ! pgrep -f '[n]ovnc_proxy.*6080' >/dev/null; then
  nohup /usr/share/novnc/utils/novnc_proxy \
    --listen 6080 \
    --vnc localhost:5901 \
    > "$HOME/.novnc.log" 2>&1 &
fi