#!/bin/sh

# Logging setup
LOGFILE="/tmp/vnc-startup.log"
exec > "$LOGFILE" 2>&1

echo "=== Starting TurboVNC & websockify launch sequence ==="
echo "Timestamp: $(date)"

# Ensure XFCE can access the system bus.
system_bus_socket="/run/dbus/system_bus_socket"

run_root() {
    if command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        "$@"
    fi
}

if ! dbus-send --system --type=method_call --print-reply \
    --dest=org.freedesktop.DBus / org.freedesktop.DBus.ListNames >/dev/null 2>&1; then
    run_root rm -f "$system_bus_socket" /run/dbus/pid
    if getent passwd messagebus >/dev/null 2>&1; then
        run_root install -d -o messagebus -g messagebus /run/dbus
    else
        run_root install -d -m 755 /run/dbus
    fi
    run_root dbus-daemon --system --fork
fi

system_bus_ready=false
for attempt in $(seq 1 10); do
    if dbus-send --system --type=method_call --print-reply \
        --dest=org.freedesktop.DBus / org.freedesktop.DBus.ListNames >/dev/null 2>&1; then
        system_bus_ready=true
        break
    fi
    sleep 1
done
if [ "$system_bus_ready" != true ]; then
    echo "ERROR: D-Bus system bus is not responding at $system_bus_socket"
    exit 1
fi

# 1. Clean up running processes
echo "[1/4] Cleaning up running processes..."
pkill Xvnc || true
pkill websockify || true
sleep 1

# 2. Clear stale X11 locks
echo "[2/4] Clearing X11 lock files..."
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 /tmp/.X2-lock /tmp/.X11-unix/X2

# 3. Configure xstartup in both user and system locations
echo "[3/4] Configuring XFCE desktop startup script..."
mkdir -p ~/.vnc

cat << 'EOF' > ~/.vnc/xstartup.turbovnc
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-launch --exit-with-session startxfce4
EOF
chmod +x ~/.vnc/xstartup.turbovnc

# Copy to system default path if writable
if [ -w /opt/TurboVNC/bin/xstartup.turbovnc ]; then
    cp ~/.vnc/xstartup.turbovnc /opt/TurboVNC/bin/xstartup.turbovnc
fi

# 4. Launch TurboVNC explicitly defining the xstartup path
echo "[4/4] Launching TurboVNC on display :1..."
/opt/TurboVNC/bin/vncserver :1 -geometry 1280x720 -depth 24 -securitytypes none -xstartup ~/.vnc/xstartup.turbovnc

# Verify TurboVNC port binding
sleep 2
if ! ss -tulpn | grep -q ":5901"; then
    echo "ERROR: TurboVNC failed to bind to port 5901!"
    echo "Checking latest TurboVNC log:"
    cat ~/.vnc/*.log | tail -n 25
    exit 1
fi

echo "TurboVNC started successfully on port 5901."

workspace_dir="$(cd -- "$(dirname -- "$0")/.." && pwd)"

# Wait for XFCE's window manager, not just the X server, before reporting success.
desktop_ready=false
for attempt in $(seq 1 30); do
    if sh "$workspace_dir/.devcontainer/watch-xfce.sh" --check; then
        desktop_ready=true
        break
    fi
    sleep 1
done
if [ "$desktop_ready" != true ]; then
    echo "ERROR: XFCE window manager did not become ready."
    tail -n 80 ~/.vnc/*.log
    exit 1
fi
# Keep XFCE alive if its session or window manager exits after startup.
# Keep XFCE alive if its session or window manager exits after startup.
watchdog_log="/tmp/xfce-watchdog.log"
nohup sh "$workspace_dir/.devcontainer/watch-xfce.sh" \
    </dev/null >>"$watchdog_log" 2>&1 &

# Start PulseAudio routing and the private browser audio receiver.
if ! bash "$workspace_dir/.devcontainer/start-audio.sh"; then
    echo "ERROR: Desktop audio services failed to start!"
    exit 1
fi

# 5. Launch websockify
echo "Starting websockify on port 6080..."
nohup websockify --web=/usr/share/novnc 6080 localhost:5901 \
    </dev/null >/tmp/websockify.log 2>&1 &

sleep 2
if curl --fail --silent http://127.0.0.1:6080/vnc.html >/dev/null; then
    echo "=== Startup complete! noVNC is ready on port 6080 ==="
else
    echo "ERROR: noVNC did not become ready on port 6080!"
    tail -n 40 /tmp/websockify.log
    exit 1
fi