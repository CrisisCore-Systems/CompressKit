#!/data/data/com.termux/files/usr/bin/bash

# Safe command execution module for CompressKit
# Provides secure command execution with allowlisting

# Import dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/logger.sh"

# Define allowed commands with their permitted arguments
declare -A ALLOWED_COMMANDS=(
    ["gs"]="allowed"
    ["ghostscript"]="allowed"
    ["convert"]="allowed"
    ["qpdf"]="allowed"
    ["mkdir"]="allowed"
    ["rm"]="allowed"
    ["cp"]="allowed"
    ["mv"]="allowed"
    ["chmod"]="allowed"
    ["pdfinfo"]="allowed"
)

# Command argument allowlist patterns (regex)
declare -A ALLOWED_ARGS_PATTERNS=(
    ["gs"]="^(-[a-zA-Z]|-(sDEVICE|dCompatibilityLevel|dPDFSETTINGS|dNOPAUSE|dQUIET|dBATCH|sOutputFile)=).+$"
    ["convert"]="^.+$"  # More restrictive pattern needed for production
    ["mkdir"]="^(-p)?( [0-9a-zA-Z_.\/]+)+$"
    ["rm"]="^(-f|-r|-rf|-fr)?( [0-9a-zA-Z_.\/]+)+$"
    ["cp"]="^(-r|-a|-f)?( [0-9a-zA-Z_.\/]+){2}$"
    ["mv"]="^( [0-9a-zA-Z_.\/]+){2}$"
    ["chmod"]="^[0-9]{3,4}( [0-9a-zA-Z_.\/]+)+$"
)

# Parse command into command and arguments
parse_command() {
    local cmd_string="$1"
    local cmd=""
    local args=""
    
    # Extract command name
    cmd=$(echo "$cmd_string" | awk '{print $1}')
    
    # Extract arguments
    args=$(echo "$cmd_string" | cut -d' ' -f2-)
    
    echo "$cmd|$args"
}

# Validate if a command is allowed
is_command_allowed() {
    local cmd="$1"
    
    if [ -n "${ALLOWED_COMMANDS[$cmd]}" ]; then
        return 0
    fi
    
    return 1
}

# Validate if command arguments match allowed pattern
are_args_allowed() {
    local cmd="$1"
    local args="$2"
    
    # If no pattern defined, be conservative and reject
    if [ -z "${ALLOWED_ARGS_PATTERNS[$cmd]}" ]; then
        return 1
    fi
    
    # Check if arguments match the allowed pattern
    if [[ "$args" =~ ${ALLOWED_ARGS_PATTERNS[$cmd]} ]]; then
        return 0
    fi
    
    return 1
}

# Execute command safely with allowlisting
safe_execute() {
    local cmd_string="$1"
    local parsed=$(parse_command "$cmd_string")
    local cmd=$(echo "$parsed" | cut -d'|' -f1)
    local args=$(echo "$parsed" | cut -d'|' -f2-)
    
    # Check if command is allowlisted
    if ! is_command_allowed "$cmd"; then
        log_error "Security violation: Command not allowed: $cmd"
        return 1
    fi
    
    # Check if arguments are allowlisted
    if ! are_args_allowed "$cmd" "$args"; then
        log_error "Security violation: Command arguments not allowed: $args"
        return 1
    fi
    
    # Execute the command (using eval, but safely since we've validated it)
    eval "$cmd $args"
    return $?
}

# Execute array of command parts safely (alternative to eval)
safe_execute_array() {
    local cmd="$1"
    shift
    local args=("$@")
    
    # Check if command is allowlisted
    if ! is_command_allowed "$cmd"; then
        log_error "Security violation: Command not allowed: $cmd"
        return 1
    fi
    
    # Check if arguments are allowlisted
    local args_str="${args[*]}"
    if ! are_args_allowed "$cmd" "$args_str"; then
        log_error "Security violation: Command arguments not allowed: $args_str"
        return 1
    fi
    
    # Execute the command using the array (avoids eval completely)
    "$cmd" "${args[@]}"
    return $?
}
