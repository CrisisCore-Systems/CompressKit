#!/data/data/com.termux/files/usr/bin/bash

# Logger module for CompressKit
# Handles all logging and debugging output

# Initialize logging
LOG_FILE="${SCRIPT_DIR}./logs/compresskit.log"
DEBUG_MODE=${DEBUG_MODE:-0}

# Create logs directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Log levels
declare -A LOG_LEVELS=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARN"]=2
    ["ERROR"]=3
    ["FATAL"]=4
)

# Initialize log file with header
init_logger() {
    cat > "$LOG_FILE" << EOF
CompressKit Log File
Started: $(date)
Version: $VERSION
===================
EOF
}

# Main logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Always write to log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Only show debug messages if debug mode is enabled
    if [ $DEBUG_MODE -eq 1 ] || [ ${LOG_LEVELS[$level]} -gt ${LOG_LEVELS["DEBUG"]} ]; then
        case $level in
            "DEBUG") ui_info "Debug: $message" ;;
            "INFO") ui_info "$message" ;;
            "WARN") ui_warning "$message" ;;
            "ERROR") ui_error "$message" ;;
            "FATAL") ui_error "Fatal: $message" ;;
        esac
    fi
}

# Convenience functions for different log levels
log_debug() { log "DEBUG" "$@"; }
log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_fatal() { log "FATAL" "$@"; }

# Function to dump the last n lines of the log
show_log() {
    local lines=${1:-50}
    if [ -f "$LOG_FILE" ]; then
        tail -n "$lines" "$LOG_FILE"
    else
        log_error "Log file not found"
    fi
}

# Clear log file
clear_log() {
    if ui_confirm "Are you sure you want to clear the log file?"; then
        init_logger
        log_info "Log file cleared"
    fi
}
