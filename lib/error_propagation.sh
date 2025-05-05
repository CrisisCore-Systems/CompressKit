#!/data/data/com.termux/files/usr/bin/bash

# Error propagation framework for CompressKit
# Standardizes error handling and propagation across modules

# Import dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/logger.sh"

# Import error codes if available
if [ -f "${SCRIPT_DIR}/error_handler.sh" ]; then
    source "${SCRIPT_DIR}/error_handler.sh"
fi

# Import security incident handler if available
if [ -f "${SCRIPT_DIR}/security/incident_handler.sh" ]; then
    source "${SCRIPT_DIR}/security/incident_handler.sh"
fi

# Function to capture and propagate errors with context
propagate_error() {
    local exit_code=$1
    local error_message="$2"
    local function_name="${3:-${FUNCNAME[1]}}"
    local error_type="${4:-UNKNOWN_ERROR}"
    
    # Log the error with context
    log_error "$error_message (in $function_name)"
    
    # Add to error stack if available
    if declare -p ERROR_STACK &>/dev/null; then
        ERROR_STACK+=("[$function_name] $error_message")
    fi
    
    # Record error for metrics and reporting
    if type record_error &>/dev/null; then
        record_error "$error_type" "$exit_code" "$error_message" "$function_name"
    fi
    
    # Return the exit code
    return $exit_code
}

# Wrapper function for critical operations with standardized error handling
try_operation() {
    local operation_func="$1"
    local error_msg="$2"
    local error_type="${3:-UNKNOWN_ERROR}"
    shift 3
    
    # Execute the operation with its arguments
    "$operation_func" "$@"
    local result=$?
    
    # Handle any error
    if [ $result -ne 0 ]; then
        propagate_error "$result" "$error_msg" "$operation_func" "$error_type"
        return $result
    fi
    
    return 0
}

# Assert that a condition is true, or propagate an error
assert() {
    local condition="$1"
    local error_msg="$2"
    local error_code="${3:-1}"
    local caller_func="${4:-${FUNCNAME[1]}}"
    
    # Evaluate the condition
    if ! eval "$condition"; then
        propagate_error "$error_code" "$error_msg" "$caller_func"
        return $error_code
    fi
    
    return 0
}

# Function to handle a security violation with appropriate response
handle_security_violation() {
    local violation_type="$1"
    local details="$2"
    local severity="${3:-HIGH}"
    
    log_error "SECURITY VIOLATION: $violation_type - $details"
    
    # Record security incident if handler available
    if type record_security_incident &>/dev/null; then
        record_security_incident "SECURITY_VIOLATION" "$severity" 8 "$violation_type: $details"
    elif type report_security_incident &>/dev/null; then
        report_security_incident "SECURITY_VIOLATION" 8
    fi
    
    # Return security violation error code if defined
    if [ -n "${ERROR_CODES[SECURITY_VIOLATION]}" ]; then
        return "${ERROR_CODES[SECURITY_VIOLATION]}"
    else
        return 8  # Default security violation code
    fi
}

# Wrapper that provides transactional behavior for file operations
transactional_file_op() {
    local operation="$1"
    local target_file="$2"
    shift 2
    
    # Create backup if file exists
    local backup_file=""
    if [ -f "$target_file" ]; then
        backup_file="${target_file}.bak"
        cp "$target_file" "$backup_file" || {
            log_error "Failed to create backup of $target_file"
            return 1
        }
    fi
    
    # Execute the operation
    "$operation" "$target_file" "$@"
    local result=$?
    
    # If operation failed and backup exists, restore
    if [ $result -ne 0 ] && [ -n "$backup_file" ] && [ -f "$backup_file" ]; then
        log_warning "Operation failed, restoring from backup"
        mv "$backup_file" "$target_file" || {
            log_error "Failed to restore backup for $target_file"
            return 2
        }
    elif [ -n "$backup_file" ]; then
        # Operation successful, remove backup
        rm -f "$backup_file"
    fi
    
    return $result
}
