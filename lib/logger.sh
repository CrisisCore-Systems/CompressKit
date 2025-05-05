#!/data/data/com.termux/files/usr/bin/bash

# Logger module for CompressKit
# Forges the threads of events into the fabric of logs
# Handles all logging and debugging output across dimensions

# Import secure utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/secure_utils.sh" ]; then
    source "${SCRIPT_DIR}/secure_utils.sh"
fi

# Initialize logging with secure defaults
VERSION=${VERSION:-"unknown"}
SCRIPT_DIR=${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
LOG_DIR=${LOG_DIR:-"${SCRIPT_DIR}/logs"}
LOG_FILE=${LOG_FILE:-"${LOG_DIR}/compresskit.log"}
DEBUG_MODE=${DEBUG_MODE:-0}
LOG_PERMISSIONS="0640"  # User read/write, group read, others none

# SECURITY FIX: Create logs directory safely with proper permissions
create_log_dir() {
    # Use safe_path if available
    local safe_log_dir
    if type safe_path &>/dev/null; then
        safe_log_dir=$(safe_path "$LOG_DIR")
        if [ $? -ne 0 ] || [ -z "$safe_log_dir" ]; then
            echo "Error: Invalid log directory path" >&2
            return 1
        fi
        LOG_DIR="$safe_log_dir"
    fi
    
    # Create directory with secure permissions
    if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        echo "Failed to create log directory at $LOG_DIR. Check permissions." >&2
        return 1
    fi
    
    # Set permissions
    chmod 750 "$LOG_DIR" 2>/dev/null
    
    return 0
}

# SECURITY FIX: Create or open log file safely
create_log_file() {
    # Check if log directory exists
    if [ ! -d "$LOG_DIR" ]; then
        create_log_dir || return 1
    fi
    
    # Use safe_path if available
    local safe_log_file
    if type safe_path &>/dev/null; then
        safe_log_file=$(safe_path "$LOG_FILE")
        if [ $? -ne 0 ] || [ -z "$safe_log_file" ]; then
            echo "Error: Invalid log file path" >&2
            return 1
        fi
        LOG_FILE="$safe_log_file"
    fi
    
    # Create file if it doesn't exist
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE" 2>/dev/null || {
            echo "Failed to create log file at $LOG_FILE. Check permissions." >&2
            return 1
        }
        chmod "$LOG_PERMISSIONS" "$LOG_FILE" 2>/dev/null
    else
        # Ensure existing file has correct permissions
        chmod "$LOG_PERMISSIONS" "$LOG_FILE" 2>/dev/null
    fi
    
    return 0
}

# Initialize log system securely
init_logger() {
    # Create log file
    create_log_file || exit 1
    
    # Write header to log file
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S %Z')
    local hostname=$(hostname 2>/dev/null || echo "unknown")
    local user=$(id -un 2>/dev/null || echo "unknown")
    
    # Sanitize command line arguments for logging
    local safe_args=""
    for arg in "$@"; do
        # Remove sensitive data or use basic sanitization
        arg="${arg//password=*/password=REDACTED}"
        arg="${arg//key=*/key=REDACTED}"
        safe_args="$safe_args $(printf '%q' "$arg")"
    done
    
    cat > "$LOG_FILE" << EOF
CompressKit Log File
====================
Started: $timestamp
Version: $VERSION
User: $user
Host: $hostname
Invocation:$safe_args
--------------------
EOF
    
    # Set appropriate permissions
    chmod "$LOG_PERMISSIONS" "$LOG_FILE" 2>/dev/null
    
    # Initialize log rotation
    rotate_logs
    
    return 0
}

# Log levels, renamed to align with narrative-driven design
declare -A LOG_LEVELS=(
    ["ORACLE"]=0    # DEBUG
    ["HERO"]=1      # INFO
    ["OMEN"]=2      # WARN
    ["DOOM"]=3      # ERROR
    ["CATASTROPHE"]=4  # FATAL
)

# SECURITY FIX: Rotate logs with safer operation
rotate_logs() {
    local max_size_kb=1024  # Set max size in KB
    
    # Check if log file exists
    if [ ! -f "$LOG_FILE" ]; then
        create_log_file || return 1
    fi
    
    # Get file size
    local file_size=0
    if command -v du &>/dev/null; then
        file_size=$(du -k "$LOG_FILE" 2>/dev/null | cut -f1)
    else
        local size_in_bytes=$(stat -c "%s" "$LOG_FILE" 2>/dev/null || \
                             stat -f "%z" "$LOG_FILE" 2>/dev/null || echo "0")
        file_size=$((size_in_bytes / 1024))
    fi
    
    # Rotate if file is too large
    if [ "$file_size" -gt "$max_size_kb" ]; then
        local timestamp=$(date '+%Y%m%d%H%M%S')
        local backup_log="${LOG_FILE}.${timestamp}"
        
        # Create secure backup
        if mv "$LOG_FILE" "$backup_log" 2>/dev/null; then
            # Set permissions on rotated log
            chmod "$LOG_PERMISSIONS" "$backup_log" 2>/dev/null
            
            # Create new log file
            create_log_file || return 1
            echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] [SYSTEM] Log file rotated" >> "$LOG_FILE"
            
            # Remove old logs (keep last 5)
            if command -v ls &>/dev/null && command -v head &>/dev/null; then
                local log_pattern="${LOG_FILE}.*"
                ls -1t $log_pattern 2>/dev/null | tail -n +6 | xargs -r rm -f
            fi
        fi
    fi
    
    return 0
}

# SECURITY FIX: Main logging function with sanitization
log() {
    local level="$1"
    shift
    
    # Validate log level
    if [ -z "${LOG_LEVELS[$level]}" ]; then
        level="HERO"  # Default to INFO level if invalid
    fi
    
    # Sanitize log message to prevent log injection
    local message="$*"
    message="${message//\r/}"  # Remove carriage returns
    message="${message//\n/ }"  # Replace newlines with spaces
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S %Z')
    
    # Ensure log file exists
    if [ ! -f "$LOG_FILE" ] || [ ! -w "$LOG_FILE" ]; then
        create_log_file || return 1
    fi
    
    # Rotate logs if needed
    rotate_logs
    
    # Always write to log file using a safer approach
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
    
    return 0
}

# Convenience functions for different log levels
log_oracle() { log "ORACLE" "$@"; }
log_heroic() { log "HERO" "$@"; }
log_omen() { log "OMEN" "$@"; }
log_doom() { log "DOOM" "$@"; }
log_cataclysm() { log "CATASTROPHE" "$@"; }

# SECURITY FIX: Function to dump the last n lines of the log
show_log() {
    local lines=${1:-50}
    
    # Validate input is a positive integer
    if [[ ! "$lines" =~ ^[0-9]+$ ]] || [ "$lines" -lt 1 ]; then
        log_doom "Invalid line count: $lines"
        lines=50  # Default to 50 lines
    fi
    
    # Ensure log file exists
    if [ ! -f "$LOG_FILE" ]; then
        log_doom "Log file not found"
        return 1
    fi
    
    # Use tail safely
    if ! tail -n "$lines" "$LOG_FILE" 2>/dev/null; then
        log_doom "Failed to read log file"
        return 1
    fi
    
    return 0
}

# SECURITY FIX: Clear log file with proper permission checks
clear_log() {
    # Check if UI functions are available
    if type ui_confirm &>/dev/null; then
        if ! ui_confirm "Are you sure you want to clear the log file?"; then
            return 1
        fi
    else
        echo "Are you sure you want to clear the log file? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Ensure log directory exists
    if [ ! -d "$LOG_DIR" ]; then
        create_log_dir || return 1
    fi
    
    # Reset log file
    init_logger
    
    # Log the action
    log_heroic "Log file cleared and reset"
    
    return 0
}

# Initialize on import
create_log_dir
create_log_file
