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
        stack_trace+="\n  at ${func_stack[i]} (line ${BASH_LINENO[i]})"
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
            # Attempt to clean temporary files
            clean_temp_files
            ;;
        "CONFIG_ERROR")
            # Attempt to restore default configuration
            log_warn "Attempting to restore default configuration..."
            create_default_config
            ;;
        "COMPRESSION_FAILED")
            # Attempt to restore original file if backup exists
            restore_backup
            ;;
    esac
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
