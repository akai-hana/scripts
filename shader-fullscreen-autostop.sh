#!/bin/bash
# Fully event-driven fullscreen shader wallpaper/picom manager script
# (by akai - fixed subshell pipe bug, requires bash for process substitution)
# This script saves on computer resources by stopping the
# shader wallpaper and picom from running when full-screening onto a program.
# Zero polling - purely event-driven using X11 events.

# Same assumptions as original:
# + Ghostty as the terminal program
# + Zen as the browser
# + Vesktop as the Discord client
# + Transparent terminal
# + Shadow (shader wallpaper program) being installed specifically under "~/git/shadow"

PICOM_PID=""
WALLPAPER_PID=""
FULLSCREEN_STATE=false

# Pause services (entering fullscreen)
pause_services() {
    echo "Pausing services..."

    if pgrep -x "picom" > /dev/null; then
        PICOM_PID=$(pgrep -x "picom")
        pkill -x "picom"
    fi

    if pgrep -x "python" > /dev/null; then
        WALLPAPER_PID=$(pgrep -x "python")
        kill -STOP "$WALLPAPER_PID"
    fi
}

# Resume services (leaving fullscreen)
resume_services() {
    echo "Resuming services..."

    # Resume wallpaper first (faster)
    if [ -n "$WALLPAPER_PID" ] && kill -0 "$WALLPAPER_PID" 2>/dev/null; then
        kill -CONT "$WALLPAPER_PID"
    else
        echo "Shadow wallpaper process not found - may need manual restart"
    fi

    # Restart picom if not already running
    if ! pgrep -x "picom" > /dev/null; then
        picom --daemon --backend glx --no-fading-openclose --fade-in-step=1 --fade-out-step=1 &
    else
        echo "Picom already running"
    fi
}

# Check if a given window ID is fullscreen (and not Ghostty)
is_window_fullscreen() {
    local window_id="$1"
    [ -n "$window_id" ] || return 1

    local window_state
    window_state=$(xprop -id "$window_id" _NET_WM_STATE 2>/dev/null \
                   | grep -o "_NET_WM_STATE_FULLSCREEN")
    [ -n "$window_state" ] || return 1

    # Exclude Ghostty fullscreen
    local window_pid
    window_pid=$(xprop -id "$window_id" _NET_WM_PID 2>/dev/null | awk '{print $3}')
    if [ -n "$window_pid" ]; then
        local process_name
        process_name=$(ps -p "$window_pid" -o comm= 2>/dev/null)
        [ "$process_name" = "ghostty" ] && return 1
    fi

    return 0
}

# Evaluate current focus/fullscreen state and act on transitions
handle_state_change() {
    local new_fullscreen_state=false

    local active_window
    active_window=$(xdotool getactivewindow 2>/dev/null)

    if [ -n "$active_window" ] && is_window_fullscreen "$active_window"; then
        new_fullscreen_state=true
    fi

    if [ "$new_fullscreen_state" != "$FULLSCREEN_STATE" ]; then
        if [ "$new_fullscreen_state" = true ]; then
            pause_services
            FULLSCREEN_STATE=true
        else
            resume_services
            FULLSCREEN_STATE=false
        fi
    fi
}

# Clean shutdown
cleanup() {
    echo "Shutting down fullscreen manager..."
    [ "$FULLSCREEN_STATE" = true ] && resume_services
    # Terminate the xev background process
    [ -n "$XEV_PID" ] && kill "$XEV_PID" 2>/dev/null
    exit 0
}

trap cleanup INT TERM EXIT

# Dependency check
for cmd in xdotool xprop xev; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd is required but not installed"
        exit 1
    fi
done

# Evaluate initial state before entering event loop
handle_state_change

echo "Event-driven fullscreen manager started. Listening for X11 window events..."

# Main event loop — process substitution keeps variables in the SAME shell,
# fixing the subshell pipe bug where FULLSCREEN_STATE / WALLPAPER_PID were
# always reset to their initial values on every event.
while IFS= read -r line; do
    case "$line" in
        *"PropertyNotify event"* | *"_NET_ACTIVE_WINDOW"* | *"_NET_WM_STATE"*)
            handle_state_change
            ;;
    esac
done < <(xev -root -event property & XEV_PID=$!; wait)
