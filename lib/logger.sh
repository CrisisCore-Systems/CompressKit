#!/data/data/com.termux/files/usr/bin/bash

# Logger module for CompressKit
# Forges the threads of events into the fabric of logs
# Handles all logging and debugging output across dimensions

# Initialize logging
LOG_DIR=${LOG_DIR:-"${SCRIPT_DIR}/logs"}
LOG_FILE="${LOG_DIR}/compresskit.log"
DEBUG_MODE=${DEBUG_MODE:-0}

# Create logs directory if it doesn't exist
if ! mkdir -p "$LOG_DIR" || ! touch "$LOG_FILE"; then
    echo "Failed to initialize log file at $LOG_FILE. Check permissions." >&2
    exit 1
fi

# Log levels, renamed to align with narrative-driven design
declare -A LOG_LEVELS=(
    ["ORACLE"]=0    # DEBUG
    ["HERO"]=1      # INFO
    ["OMEN"]=2      # WARN
    ["DOOM"]=3      # ERROR
    ["CATASTROPHE"]=4  # FATAL
)

# Rotate logs to maintain a clean timeline
rotate_logs() {
    local max_size_kb=1024  # Set max size in KB
    if [ -f "$LOG_FILE" ] && [ $(du -k "$LOG_FILE" | cut -f1) -gt "$max_size_kb" ]; then
        mv "$LOG_FILE" "${LOG_FILE}.1"
        : > "$LOG_FILE"  # Truncate the log file
        log_heroic "Log file rotated"
    fi
}

# Initialize log file with header
init_logger() {
    cat > "$LOG_FILE" << EOF
CompressKit Log File
====================
Started: $(date)
Version: $VERSION
Invocation: $0 $@
Log Node: $(hostname)
--------------------
EOF
}

# Main logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S %Z')
    
    # Rotate logs if needed
    rotate_logs
    
    # Always write to log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Only show messages if appropriate level is met
    if [ $DEBUG_MODE -eq 1 ] || [ ${LOG_LEVELS[$level]} -ge ${LOG_LEVELS["HERO"]} ]; then
        case $level in
            "ORACLE") ui_info "Prophecy: $message" ;;
            "HERO") ui_info "Heroic Deed: $message" ;;
            "OMEN") ui_warning "Omen: $message" ;;
            "DOOM") ui_error "Doom: $message" ;;
            "CATASTROPHE") ui_error "Cataclysm: $message" ;;
        esac
    fi
}

# Convenience functions for different log levels
log_oracle() { log "ORACLE" "$@"; }
log_heroic() { log "HERO" "$@"; }
log_omen() { log "OMEN" "$@"; }
log_doom() { log "DOOM" "$@"; }
log_cataclysm() { log "CATASTROPHE" "$@"; }

# Function to dump the last n lines of the log
show_log() {
    local lines=${1:-50}
    if [ -f "$LOG_FILE" ]; then
        tail -n "$lines" "$LOG_FILE"
    else
        log_doom "Log file not found"
    fi
}

# Clear log file
clear_log() {
    if ui_confirm "Are you sure you want to clear the log file?"; then
        init_logger
        log_heroic "Log file cleared and reset"
    fi
}
