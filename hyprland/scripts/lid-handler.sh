#!/bin/bash

# Hyprland Lid Handler - Workspace Migration Script
# Automatically moves workspaces from laptop display to external monitor on lid close

LOG_FILE="$HOME/.config/hypr/scripts/lid-handler.log"
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

# Function to handle lid close
handle_lid_close() {
    log "Lid closed - starting handler"
    
    # Detect external monitor
    external_monitor=$(get_external_monitor)
    
    if [ $? -eq 0 ]; then
        log "External monitor detected: $external_monitor"
        
        # Get all windows on laptop monitor
        local windows=$(hyprctl clients -j | jq -r ".[] | select(.monitor == \"$LAPTOP_MONITOR\") | .address")
        local window_count=$(echo "$windows" | grep -c "0x")
        
        log "Found $window_count windows on $LAPTOP_MONITOR"
        
        # Move each window to the external monitor (maintaining workspace)
        if [ -n "$windows" ]; then
            while IFS= read -r window_addr; do
                if [ -n "$window_addr" ] && [ "$window_addr" != "null" ]; then
                    log "Moving window $window_addr to $external_monitor"
                    hyprctl dispatch movewindow "mon:$external_monitor,address:$window_addr" 2>&1 | tee -a "$LOG_FILE"
                fi
            done <<< "$windows"
        fi
        
        # Small delay to ensure windows are moved
        sleep 0.5
        
        # Disable laptop monitor
        log "Disabling $LAPTOP_MONITOR"
        hyprctl keyword monitor "$LAPTOP_MONITOR, disable" 2>&1 | tee -a "$LOG_FILE"
        
        log "Lid close handler completed successfully"
    else
        log "No external monitor detected"
        
        # Disable laptop monitor (but keep system running)
        log "Disabling $LAPTOP_MONITOR (screen off, system stays on)"
        hyprctl keyword monitor "$LAPTOP_MONITOR, disable" 2>&1 | tee -a "$LOG_FILE"
        
        log "Lid close handler completed - screen off, system running"
    fi
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

# Function to handle lid open
handle_lid_open() {
    log "Lid opened - starting handler"
    
    # Small delay to let system settle after wake
    sleep 0.5
    
    # Re-enable laptop monitor with preferred settings
    log "Re-enabling $LAPTOP_MONITOR"
    hyprctl keyword monitor "$LAPTOP_MONITOR, preferred, auto, 1.2" 2>&1 | tee -a "$LOG_FILE"
    
    # Check if external monitors are still connected
    external_monitor=$(get_external_monitor)
    
    if [ $? -eq 0 ]; then
        log "External monitor still connected: $external_monitor"
        log "Both displays active - windows remain on external monitor"
        
        # Restart UI services to ensure they appear on both monitors
        restart_ui_services
    else
        log "No external monitor detected - laptop only mode"
        log "Moving windows back to laptop monitor"
        
        # Get all windows (they should be on workspaces but monitor might be missing)
        local all_windows=$(hyprctl clients -j | jq -r ".[].address")
        
        # Move all windows to laptop monitor
        if [ -n "$all_windows" ]; then
            while IFS= read -r window_addr; do
                if [ -n "$window_addr" ] && [ "$window_addr" != "null" ]; then
                    log "Moving window $window_addr to $LAPTOP_MONITOR"
                    hyprctl dispatch movewindow "mon:$LAPTOP_MONITOR,address:$window_addr" 2>&1 >> "$LOG_FILE"
                fi
            done <<< "$all_windows"
        fi
        
        # Restart UI services to restore waybar and wallpaper on laptop screen
        restart_ui_services
    fi
    
    log "Lid open handler completed successfully"
}

# Main logic
case "$1" in
    close)
        handle_lid_close
        ;;
    open)
        handle_lid_open
        ;;
    *)
        echo "Usage: $0 {close|open}"
        log "Error: Invalid argument '$1'. Usage: $0 {close|open}"
        exit 1
        ;;
esac

exit 0
