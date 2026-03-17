#!/bin/bash

# Hyprland Monitor Hotplug Handler
# Listens for monitor connect/disconnect events and handles workspace migration

LOG_FILE="$HOME/.config/hypr/scripts/monitor-hotplug.log"
LAPTOP_MONITOR="eDP-1"
PREFERRED_EXTERNAL="DP-5"
FALLBACK_EXTERNAL="DP-6"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to get connected external monitor
get_external_monitor() {
    local monitors=$(hyprctl monitors -j)
    
    # Check if preferred external (DP-5) is connected
    if echo "$monitors" | jq -e ".[] | select(.name == \"$PREFERRED_EXTERNAL\")" > /dev/null 2>&1; then
        echo "$PREFERRED_EXTERNAL"
        return 0
    fi
    
    # Check if fallback external (DP-6) is connected
    if echo "$monitors" | jq -e ".[] | select(.name == \"$FALLBACK_EXTERNAL\")" > /dev/null 2>&1; then
        echo "$FALLBACK_EXTERNAL"
        return 0
    fi
    
    # No external monitor found
    return 1
}

# Function to restart UI services
restart_ui_services() {
    log "Restarting UI services (waybar and wallpaper)"
    
    # Restart waybar
    pkill waybar
    sleep 0.3
    uwsm-app -- waybar &
    
    # Restart wallpaper
    pkill swaybg
    sleep 0.3
    uwsm-app -- swaybg -i ~/.config/omarchy/current/background -m fill &
    
    log "UI services restarted"
}

# Function to handle monitor disconnect (external monitor removed)
handle_monitor_disconnect() {
    log "Monitor disconnect detected"
    
    # Check if any external monitor is still connected
    external_monitor=$(get_external_monitor)
    
    if [ $? -ne 0 ]; then
        log "No external monitors - switching to laptop-only mode"
        
        # Move all windows to laptop monitor
        local all_windows=$(hyprctl clients -j | jq -r ".[].address")
        
        if [ -n "$all_windows" ]; then
            log "Moving all windows to $LAPTOP_MONITOR"
            while IFS= read -r window_addr; do
                if [ -n "$window_addr" ] && [ "$window_addr" != "null" ]; then
                    hyprctl dispatch movewindow "mon:$LAPTOP_MONITOR,address:$window_addr" 2>&1 >> "$LOG_FILE"
                fi
            done <<< "$all_windows"
        fi
        
        # Restart UI services to restore waybar and wallpaper
        restart_ui_services
        
        log "Switched to laptop-only mode successfully"
    else
        log "External monitor still connected: $external_monitor"
        # Restart UI services to ensure proper rendering
        restart_ui_services
    fi
}

# Function to handle monitor connect (external monitor added)
handle_monitor_connect() {
    local monitor_name="$1"
    log "Monitor connect detected: $monitor_name"
    
    # Restart UI services to ensure they appear on all monitors
    restart_ui_services
    
    log "Monitor connect handled successfully"
}

# Listen to Hyprland socket for monitor events
log "Starting monitor hotplug handler"

# Use socat to listen to Hyprland socket
HYPRLAND_INSTANCE_SIGNATURE="$HYPRLAND_INSTANCE_SIGNATURE"
SOCKET_PATH="/run/user/$(id -u)/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

if [ ! -S "$SOCKET_PATH" ]; then
    log "Error: Hyprland event socket not found at $SOCKET_PATH"
    exit 1
fi

log "Listening on socket: $SOCKET_PATH"

socat -U - UNIX-CONNECT:"$SOCKET_PATH" | while read -r line; do
    # Monitor removed event: monitorremoved>>MONITOR_NAME
    if echo "$line" | grep -q "monitorremoved"; then
        monitor_name=$(echo "$line" | cut -d'>' -f3)
        log "Event: Monitor removed - $monitor_name"
        
        # Only handle if it's an external monitor being removed
        if [ "$monitor_name" = "$PREFERRED_EXTERNAL" ] || [ "$monitor_name" = "$FALLBACK_EXTERNAL" ]; then
            handle_monitor_disconnect
        fi
    fi
    
    # Monitor added event: monitoradded>>MONITOR_NAME
    if echo "$line" | grep -q "monitoradded"; then
        monitor_name=$(echo "$line" | cut -d'>' -f3)
        log "Event: Monitor added - $monitor_name"
        
        # Only handle if it's an external monitor being added
        if [ "$monitor_name" = "$PREFERRED_EXTERNAL" ] || [ "$monitor_name" = "$FALLBACK_EXTERNAL" ]; then
            handle_monitor_connect "$monitor_name"
        fi
    fi
done
