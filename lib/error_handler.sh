#!/data/data/com.termux/files/usr/bin/bash

# Error handling and recovery module for CompressKit

# Import secure utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/secure_utils.sh"

# Also import the new security incident handler
if [ -f "${SCRIPT_DIR}/security/incident_handler.sh" ]; then
    source "${SCRIPT_DIR}/security/incident_handler.sh"
fi

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
    ["SECURITY_VIOLATION"]=8
    ["INVALID_PATH"]=9
    ["LICENSE_ERROR"]=10
    ["NETWORK_ERROR"]=11
    ["TIMEOUT"]=12
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
    ["SECURITY_VIOLATION"]="Security violation detected"
    ["INVALID_PATH"]="Invalid or unsafe file path"
    ["LICENSE_ERROR"]="License validation failed"
    ["NETWORK_ERROR"]="Network communication failed"
    ["TIMEOUT"]="Operation timed out"
    ["UNKNOWN_ERROR"]="An unknown error occurred"
)

# Stack trace array
declare -a ERROR_STACK

# Centralized configuration
# SECURITY FIX: Use the safe_path function to validate the path
CONFIG_PATH="${HOME}/.config/compresskit/config.sh"
CONFIG_FILE=$(safe_path "$CONFIG_PATH")

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Initialize error handling
init_error_handler() {
    # Save original error handling state
    ORIGINAL_ERREXIT=$(set -o | grep 'errexit' | awk '{print $2}')
    ORIGINAL_PIPEFAIL=$(set -o | grep 'pipefail' | awk '{print $2}')
    ORIGINAL_NOUNSET=$(set -o | grep 'nounset' | awk '{print $2}')
    
    # Set strict error handling
    set -o errexit
    set -o pipefail
    set -o nounset
    
    # Set up error trap
    trap 'handle_error $? ${FUNCNAME[*]} ${BASH_LINENO[*]}' ERR
    
    # Initialize error stack
    ERROR_STACK=()
    
    log_info "Error handler initialized with strict mode"
}

# Restore original error handling settings
restore_error_handler() {
    # Restore original settings
    if [ "$ORIGINAL_ERREXIT" = "off" ]; then set +o errexit; else set -o errexit; fi
    if [ "$ORIGINAL_PIPEFAIL" = "off" ]; then set +o pipefail; else set -o pipefail; fi
    if [ "$ORIGINAL_NOUNSET" = "off" ]; then set +o nounset; else set -o nounset; fi
    
    # Remove error trap
    trap - ERR
    
    log_info "Error handler restored to original settings"
}

# Main error handling function
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
        stack_trace+="\n  at ${func_stack[i]} (${BASH_SOURCE[i+1]:-unknown}, line ${BASH_LINENO[i]})"
    done
    
    # Log error with detailed information
    log_error "$error_msg (code: $exit_code)"
    log_debug "Stack trace:$stack_trace"
    
    # Show user-friendly message if UI functions are available
    if command -v ui_error &>/dev/null; then
        ui_error "$error_msg"
    else
        echo "ERROR: $error_msg" >&2
    fi
    
    # Add to error stack for later analysis
    ERROR_STACK+=("[$error_type] $error_msg")
    
    # Attempt recovery
    recover_from_error "$error_type" "$exit_code"
    
    return "$exit_code"
}

# Enhanced error recovery function
recover_from_error() {
    local error_type="$1"
    local exit_code="$2"
    
    log_info "Attempting to recover from error: $error_type"
    
    case "$error_type" in
        "DISK_FULL")
            log_info "Attempting to free disk space..."
            clean_temp_files
            ;;
        "CONFIG_ERROR")
            log_info "Attempting to restore default configuration..."
            if command -v create_default_config &>/dev/null; then
                create_default_config
            fi
            ;;
        "COMPRESSION_FAILED")
            log_info "Attempting to restore backup..."
            restore_backup
            ;;
        "DEPENDENCY_MISSING")
            log_info "Checking for alternative implementations..."
            find_alternative_dependency
            ;;
        "SECURITY_VIOLATION")
            log_warning "Security violation detected. Reporting incident..."
            report_security_incident "$error_type" "$exit_code"
            ;;
        *)
            log_warning "No specific recovery for error type: $error_type"
            if [ "$exit_code" -ge 8 ]; then
                notify_admin "$error_type"
            fi
            ;;
    esac
    
    # Check if recovery was successful
    if [ $? -eq 0 ]; then
        log_info "Recovery successful for error: $error_type"
    else
        log_warning "Recovery failed for error: $error_type"
    fi
}

# Validate required dependencies
validate_dependencies() {
    local dependencies=("$@")
    local missing=()
    
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
            log_error "Missing dependency: $cmd"
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        exit "${ERROR_CODES["DEPENDENCY_MISSING"]}"
    fi
    
    log_debug "All dependencies validated: ${dependencies[*]}"
    return 0
}

# Find alternative dependencies
find_alternative_dependency() {
    # Implementation depends on specific dependencies
    # Example: If ghostscript is missing, try pdftk, etc.
    log_info "Searching for alternative dependencies..."
    
    # This is a placeholder - implement specific alternatives
    return 1
}

# Update report_security_incident to use the new incident handler if available
report_security_incident() {
    local error_type="$1"
    local exit_code="$2"
    
    # If we have the new incident handler, use it
    if type record_security_incident &>/dev/null; then
        # Determine severity based on error type
        local severity="MEDIUM"
        case "$error_type" in
            "SECURITY_VIOLATION")
                severity="HIGH"
                ;;
            *) 
                # Default severity for other errors
                if [ "$exit_code" -ge 8 ]; then
                    severity="HIGH"
                else
                    severity="MEDIUM"
                fi
                ;;
        esac
        
        # Record the incident with the new handler
        record_security_incident "$error_type" "$severity" "$exit_code"
        return $?
    fi
    
    # Fall back to the legacy incident reporting if new handler not available
    local timestamp=$(date '+%Y%m%d%H%M%S')
    local report_file="${HOME}/.compresskit/security/incident_${timestamp}.log"
    
    # Generate and sanitize report file name
    report_file=$(safe_path "$report_file")
    
    if [ $? -ne 0 ]; then
        log_error "Failed to create security incident report path"
        return 1
    fi
    
    # Ensure directory exists
    mkdir -p "$(dirname "$report_file")"
    
    # Create detailed report
    {
        echo "====== SECURITY INCIDENT REPORT ======"
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "Error Type: $error_type"
        echo "Exit Code: $exit_code"
        echo "Username: $(id -un 2>/dev/null || echo 'unknown')"
        echo "Hostname: $(hostname 2>/dev/null || echo 'unknown')"
        echo "Working Directory: $PWD"
        echo "Command: $0 $*"
        echo "Stack Trace:"
        for error in "${ERROR_STACK[@]}"; do
            echo "  $error"
        done
        echo "====================================="
    } > "$report_file"
    
    # Set secure permissions
    chmod 600 "$report_file"
    
    log_warning "Security incident report created: $report_file"
    
    # Notify admin if configured
    notify_admin "SECURITY_INCIDENT" "$report_file"
    
    return 0
}

# Notify admin of critical errors
notify_admin() {
    local error_type="$1"
    local details="$2"
    local admin_email
    
    # Get admin email from config or use default
    if command -v get_config &>/dev/null; then
        admin_email=$(get_config "admin_email" "admin@example.com")
    else
        admin_email="admin@example.com"
    fi
    
    # Use safe email function if available
    if command -v safe_send_email &>/dev/null; then
        log_info "Notifying admin about $error_type"
        safe_send_email "$admin_email" "CompressKit Error: $error_type" "Details: $details"
        return $?
    else
        log_warning "Email notification not available"
        return 1
    fi
}

# Clean temporary files
clean_temp_files() {
    local temp_dir
    
    # Get temp directory from config or use default
    if command -v get_config &>/dev/null; then
        temp_dir=$(get_config "temp_dir" "/tmp/compresskit")
    else
        temp_dir="/tmp/compresskit"
    fi
    
    # Validate the path
    local safe_temp_dir
    safe_temp_dir=$(safe_path "$temp_dir")
    
    if [ $? -ne 0 ] || [ -z "$safe_temp_dir" ]; then
        log_error "Invalid temp directory path"
        return 1
    fi
    
    if [ -d "$safe_temp_dir" ]; then
        log_info "Cleaning temporary files from $safe_temp_dir"
        
        # SECURITY FIX: Add specific pattern matching to prevent deletion of unintended files
        find "$safe_temp_dir" -type f -name "compresskit-*" -delete || {
            log_error "Failed to clean temporary files"
            return 1
        }
        
        log_info "Temporary files cleaned successfully"
        return 0
    else
        log_warning "Temp directory not found: $safe_temp_dir"
        return 1
    fi
}

# Restore backup
restore_backup() {
    local backup_dir
    local current_file="$1"
    
    # Get backup directory from config or use default
    if command -v get_config &>/dev/null; then
        backup_dir=$(get_config "backup_dir" "${HOME}/.compresskit/backups")
    else
        backup_dir="${HOME}/.compresskit/backups"
    fi
    
    # Validate paths
    local safe_backup_dir
    safe_backup_dir=$(safe_path "$backup_dir")
    
    if [ $? -ne 0 ] || [ -z "$safe_backup_dir" ]; then
        log_error "Invalid backup directory path"
        return 1
    fi
    
    if [ ! -d "$safe_backup_dir" ]; then
        log_warning "Backup directory does not exist: $safe_backup_dir"
        return 1
    fi
    
    # If current file not specified, try to restore all recent backups
    if [ -z "$current_file" ]; then
        log_info "Attempting to restore all recent backups"
        # Implementation depends on backup naming convention
        return 1
    fi
    
    local safe_current_file
    safe_current_file=$(safe_path "$current_file")
    
    if [ $? -ne 0 ] || [ -z "$safe_current_file" ]; then
        log_error "Invalid current file path"
        return 1
    fi
    
    local backup_file="$safe_backup_dir/$(basename "$safe_current_file").backup"
    
    if [ -f "$backup_file" ]; then
        log_info "Restoring backup: $backup_file -> $safe_current_file"
        
        # Use safe_execute for secure copying
        if command -v safe_execute &>/dev/null; then
            safe_execute "cp \"$backup_file\" \"$safe_current_file\""
        else
            cp "$backup_file" "$safe_current_file"
        fi
        
        if [ $? -eq 0 ]; then
            log_info "Backup restored successfully"
            return 0
        else
            log_error "Failed to restore backup"
            return 1
        fi
    else
        log_warning "No backup found for: $safe_current_file"
        return 1
    fi
}

# Better logging functions that use structured format
# These will use the logger module if available, otherwise fallback to simple output
log_error() {
    local message="$1"
    if command -v log &>/dev/null; then
        log "DOOM" "$message"
    else
        local log_file=${LOG_FILE:-"/tmp/compresskit.log"}
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $message" >> "$log_file" 2>/dev/null
        echo "[ERROR] $message" >&2
    fi
}

log_warning() {
    local message="$1"
    if command -v log &>/dev/null; then
        log "OMEN" "$message"
    else
        local log_file=${LOG_FILE:-"/tmp/compresskit.log"}
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $message" >> "$log_file" 2>/dev/null
        echo "[WARNING] $message" >&2
    fi
}

log_info() {
    local message="$1"
    if command -v log &>/dev/null; then
        log "HERO" "$message"
    else
        local log_file=${LOG_FILE:-"/tmp/compresskit.log"}
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $message" >> "$log_file" 2>/dev/null
    fi
}

log_debug() {
    local message="$1"
    if command -v log &>/dev/null; then
        log "ORACLE" "$message"
    else
        local log_file=${LOG_FILE:-"/tmp/compresskit.log"}
        if [ "${DEBUG_MODE:-0}" -eq 1 ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $message" >> "$log_file" 2>/dev/null
        fi
    fi
}

# Display user-friendly error messages
ui_error() {
    if command -v ui_error &>/dev/null && [ "$(type -t ui_error)" = "function" ] && [ "$(type -t ui_error)" != "$FUNCNAME" ]; then
        # Call the actual UI error function if it exists and is not this function
        command ui_error "$@"
    else
        echo -e "\033[1;31mERROR\033[0m: $1. Please check the logs for more details." >&2
    fi
}

# Initialize on import
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # When sourced, don't auto-initialize
    :
else
    # When run directly, show usage
    echo "CompressKit Error Handler Module"
    echo "Usage: source $(basename "$0")"
fi
