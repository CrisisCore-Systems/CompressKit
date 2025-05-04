#!/data/data/com.termux/files/usr/bin/bash

# Error handling and recovery module for CompressKit

# Error codes
declare -A ERROR_CODES=(
    ["SUCCESS"]=0
    ["INVALID_INPUT"]=1
    ["FILE_NOT_FOUND"]=2
    ["PERMISSION_DENIED"]=3
    ["DISK_FULL"]=4
    ["COMPRESSION_FAILED"]=5
    ["CONFIG_ERROR"]=6
    ["DEPENDENCY_MISSING"]=7
    ["UNKNOWN_ERROR"]=99
)

# Error messages
declare -A ERROR_MESSAGES=(
    ["SUCCESS"]="Operation completed successfully"
    ["INVALID_INPUT"]="Invalid input parameters"
    ["FILE_NOT_FOUND"]="File or directory not found"
    ["PERMISSION_DENIED"]="Permission denied"
    ["DISK_FULL"]="Insufficient disk space"
    ["COMPRESSION_FAILED"]="PDF compression failed"
    ["CONFIG_ERROR"]="Configuration error"
    ["DEPENDENCY_MISSING"]="Required dependency not found"
    ["UNKNOWN_ERROR"]="An unknown error occurred"
)

# Stack trace array
declare -a ERROR_STACK

# Centralized configuration
CONFIG_FILE="/path/to/config.sh"
source "$CONFIG_FILE"

# Initialize error handling
init_error_handler() {
    set -o errexit
    set -o pipefail
    set -o nounset
    
    # Set up error trap
    trap 'handle_error $? ${FUNCNAME[*]} ${BASH_LINENO[*]}' ERR
}

# Error handling function
handle_error() {
    local exit_code=$1
    shift
    local func_stack=("$@")
    
    # Get error type
    local error_type="UNKNOWN_ERROR"
    for key in "${!ERROR_CODES[@]}"; do
        if [ "${ERROR_CODES[$key]}" -eq "$exit_code" ]; then
            error_type="$key"
            break
        fi
    done
    
    # Build error message
    local error_msg="${ERROR_MESSAGES[$error_type]}"
    local stack_trace=""
    
    # Build stack trace
    for ((i=0; i<${#func_stack[@]}; i++)); do
        stack_trace+="\n  at ${func_stack[i]} (script ${BASH_SOURCE[i]}, line ${BASH_LINENO[i]})"
    done
    
    # Log error
    log_error "$error_msg"
    log_debug "Stack trace:$stack_trace"
    
    # Show user-friendly message
    ui_error "$error_msg"
    
    # Add to error stack
    ERROR_STACK+=("$error_msg")
    
    # Attempt recovery
    recover_from_error "$error_type"
    
    return "$exit_code"
}

# Error recovery function
recover_from_error() {
    local error_type="$1"
    
    case "$error_type" in
        "DISK_FULL")
            clean_temp_files
            ;;
        "CONFIG_ERROR")
            log_warn "Attempting to restore default configuration..."
            create_default_config
            ;;
        "COMPRESSION_FAILED")
            restore_backup
            ;;
        *)
            log_error "Unhandled error type: $error_type. Escalating..."
            notify_admin "$error_type"
            ;;
    esac
}

# Validate dependencies
validate_dependencies() {
    local dependencies=("bash" "mail" "rm" "cp")
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Missing dependency: $cmd"
            exit "${ERROR_CODES["DEPENDENCY_MISSING"]}"
        fi
    done
}

# Notify admin of critical errors
notify_admin() {
    local error_type="$1"
    echo "Critical error detected: $error_type" | mail -s "CompressKit Error Notification" admin@example.com
}

# Clean temporary files
clean_temp_files() {
    local temp_dir=$(get_config "temp_dir" "/tmp/compresskit")
    
    if [ -d "$temp_dir" ]; then
        log_info "Cleaning temporary files..."
        rm -rf "${temp_dir:?}"/*
    fi
}

# Restore backup
restore_backup() {
    local backup_dir=$(get_config "backup_dir")
    local current_file="$1"
    
    if [ -f "$backup_dir/${current_file}.backup" ]; then
        log_info "Restoring backup..."
        cp "$backup_dir/${current_file}.backup" "$current_file"
    fi
}

# Display user-friendly error messages
ui_error() {
    echo "ERROR: $1. Please check the logs for more details."
}

# Logging functions
log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >> /path/to/logfile.log
}

log_debug() {
    echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $1" >> /path/to/logfile.log
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1" >> /path/to/logfile.log
}

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1" >> /path/to/logfile.log
}

# Test error handling (optional for development)
test_error_handling() {
    init_error_handler
    
    # Simulate errors
    handle_error "${ERROR_CODES["INVALID_INPUT"]}" "test_func"
    handle_error "${ERROR_CODES["DISK_FULL"]}" "test_func"
    
    echo "Error handling tests completed."
}
