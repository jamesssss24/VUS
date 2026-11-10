#!/bin/sh

display=":1"
logfile="/tmp/xfce-watchdog.log"
session_start_pid=""
vnc_start_pid=""

window_manager_is_ready() {
    wm_window=$(DISPLAY="$display" xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null \
        | sed -n 's/.*window id # \(0x[[:xdigit:]]*\).*/\1/p')
    [ -n "$wm_window" ] || return 1

    wm_info=$(DISPLAY="$display" xprop -id "$wm_window" _NET_WM_NAME _NET_WM_PID 2>/dev/null) \
        || return 1
    printf '%s\n' "$wm_info" | grep -q '"Xfwm4"' || return 1

    wm_pid=$(printf '%s\n' "$wm_info" \
        | sed -n 's/.*_NET_WM_PID(CARDINAL) = \([0-9][0-9]*\).*/\1/p')
    [ -n "$wm_pid" ] && kill -0 "$wm_pid" 2>/dev/null
}

vnc_backend_is_running() {
    timeout 2 bash -c '
        exec 3<>/dev/tcp/127.0.0.1/5901
        IFS= read -r -N 12 banner <&3
        [[ "$banner" == RFB* ]]
    ' >/dev/null 2>&1
}

if [ "${1:-}" = "--check" ]; then
    window_manager_is_ready
    exit $?
fi

exec 9>/tmp/xfce-watchdog.lock
if ! flock -n 9; then
    exit 0
fi

echo "XFCE watchdog started."
while :; do
    if ! vnc_backend_is_running; then
        if [ -z "$vnc_start_pid" ] || ! kill -0 "$vnc_start_pid" 2>/dev/null; then
            if [ -f /tmp/.X1-lock ]; then
                lock_pid=$(tr -cd '0-9' </tmp/.X1-lock)
                if [ -n "$lock_pid" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
                    rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
                fi
            fi
            echo "$(date): TurboVNC backend is unavailable; restarting display :1."
            nohup /opt/TurboVNC/bin/vncserver :1 \
                -geometry 1280x720 \
                -depth 24 \
                -securitytypes none \
                -xstartup "$HOME/.vnc/xstartup.turbovnc" \
                >>"$logfile" 2>&1 </dev/null &
            vnc_start_pid=$!
        fi
    elif DISPLAY="$display" xset q >/dev/null 2>&1; then
        session_pid=$(pgrep -xo xfce4-session || true)
        if [ -z "$session_pid" ]; then
            if [ -z "$session_start_pid" ] || ! kill -0 "$session_start_pid" 2>/dev/null; then
                echo "$(date): XFCE session is missing; restarting it."
                nohup dbus-launch --exit-with-session startxfce4 \
                    >>"$logfile" 2>&1 </dev/null &
                session_start_pid=$!
            fi
        elif ! window_manager_is_ready; then
            session_bus=$(tr '\000' '\n' <"/proc/$session_pid/environ" \
                | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p')
            if [ -n "$session_bus" ] && ! pgrep -x xfwm4 >/dev/null; then
                echo "$(date): XFCE is running without a window manager; restarting xfwm4."
                DISPLAY="$display" DBUS_SESSION_BUS_ADDRESS="$session_bus" \
                    nohup xfwm4 --replace >>"$logfile" 2>&1 </dev/null &
            fi
        fi
    fi
    sleep 5
done
