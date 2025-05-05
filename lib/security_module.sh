#!/data/data/com.termux/files/usr/bin/bash

# Security Module for CompressKit
# A comprehensive collection of security-related functions and utilities
# This module consolidates and extends the secure_utils.sh functionality

# Error codes specific to security operations
readonly SECURITY_SUCCESS=0
readonly SECURITY_ERROR_GENERAL=1
readonly SECURITY_ERROR_VALIDATION=2
readonly SECURITY_ERROR_PERMISSION=3
readonly SECURITY_ERROR_PATH_TRAVERSAL=4
readonly SECURITY_ERROR_COMMAND_INJECTION=5
readonly SECURITY_ERROR_SYMLINK=6
readonly SECURITY_ERROR_PARAMETER=7

# Load dependencies if not already loaded
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import error handler if available
if [ -f "${SCRIPT_DIR}/error_handler.sh" ] && ! command -v log_error &>/dev/null; then
    source "${SCRIPT_DIR}/error_handler.sh"
fi

# Logging functions - use existing logger if available or provide minimal versions
if ! command -v log_error &>/dev/null; then
    log_error() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&2
    }
    
    log_warning() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $*" >&2
    }
    
    log_info() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" >&2
    }
    
    log_debug() {
        if [ "${DEBUG_MODE:-0}" -eq 1 ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $*" >&2
        fi
    }
fi

#
# SAFE PATH HANDLING
#

# Validate and sanitize a file path to prevent path traversal
# @param {string} path - The file path to validate
# @param {string} safety_level - Optional safety level: strict|normal|relaxed
# @returns {string} Sanitized path or empty string on failure
safe_path() {
    local path="$1"
    local safety_level="${2:-strict}"
    
    # Reject empty paths
    if [ -z "$path" ]; then
        log_error "Empty path provided"
        return $SECURITY_ERROR_PARAMETER
    fi
    
    # Validate safety level
    if ! validate_path_safety_level "$safety_level"; then
        return $SECURITY_ERROR_PARAMETER
    fi
    
    # Remove any null bytes (potential exploit vector)
    path="${path//$'\0'/}"
    
    # Enhanced path traversal protection
    # Check for relative path components that could be used for traversal
    if [[ "$path" == *".."* || "$path" =~ (/\./)|(/\.$) ]]; then
        log_error "Path contains forbidden traversal components: $path"
        return $SECURITY_ERROR_PATH_TRAVERSAL
    fi
    
    # Check for URL encoded traversal attempts
    if [[ "$path" == *"%2e"* || "$path" == *"%2E"* ]]; then
        log_error "Path contains URL encoded traversal components: $path"
        return $SECURITY_ERROR_PATH_TRAVERSAL
    fi
    
    # Normalize path using realpath if available
    local resolved_path
    if command -v realpath &>/dev/null; then
        resolved_path=$(realpath -s "$path" 2>/dev/null)
        if [ $? -ne 0 ]; then
            log_error "Failed to resolve path: $path"
            return $SECURITY_ERROR_PATH_TRAVERSAL
        fi
    else
        # Fallback method for systems without realpath
        # Convert path to absolute if it's relative
        if [[ "$path" != /* ]]; then
            path="$PWD/$path"
        fi
        
        # Basic path normalization for .. and . components
        local parts=()
        local IFS='/'
        read -ra parts <<< "$path"
        local normalized=()
        
        for part in "${parts[@]}"; do
            if [ "$part" = "." ] || [ -z "$part" ]; then
                continue
            elif [ "$part" = ".." ]; then
                if [ ${#normalized[@]} -gt 0 ]; then
                    unset "normalized[${#normalized[@]}-1]"
                fi
            else
                normalized+=("$part")
            fi
        done
        
        # Rebuild the path
        resolved_path="/"
        for part in "${normalized[@]}"; do
            resolved_path+="$part/"
        done
        resolved_path="${resolved_path%/}"  # Remove trailing slash
    fi
    
    # Additional security checks based on safety level
    case "$safety_level" in
        "strict")
            # Explicit symlink check for sensitive directories
            if [[ "$resolved_path" == *"/etc"* || "$resolved_path" == *"/bin"* || "$resolved_path" == *"/sbin"* || 
                  "$resolved_path" == *"/usr"* || "$resolved_path" == *"/lib"* ]]; then
                # Check if the path is a symlink
                if [ -L "$resolved_path" ]; then
                    log_error "Security restriction - symlinks not allowed in sensitive directories: $resolved_path"
                    return $SECURITY_ERROR_SYMLINK
                fi
            fi
            
            # Prohibit access to certain system files
            for forbidden in "/etc/shadow" "/etc/passwd" "/etc/sudoers"; do
                if [[ "$resolved_path" == "$forbidden"* ]]; then
                    log_error "Security restriction - access to sensitive system file prohibited: $resolved_path"
                    return $SECURITY_ERROR_PERMISSION
                fi
            done
            ;;
        "normal")
            # Less restrictive checks for normal mode
            if [[ "$resolved_path" == "/etc/shadow" ]]; then
                log_error "Security restriction - access to shadow file prohibited"
                return $SECURITY_ERROR_PERMISSION
            fi
            ;;
        "relaxed")
            # Minimal checks for relaxed mode
            ;;
    esac
    
    echo "$resolved_path"
    return $SECURITY_SUCCESS
}

# Validate path safety level
# @param {string} level - Safety level to validate
# @returns {boolean} true if valid, false otherwise
validate_path_safety_level() {
    local level="$1"
    
    # Check if the level is valid
    case "$level" in
        "strict"|"normal"|"relaxed") 
            return $SECURITY_SUCCESS
            ;;
        *)
            log_error "Invalid path safety level: $level"
            log_error "Valid options are: strict, normal, relaxed"
            return $SECURITY_ERROR_PARAMETER
            ;;
    esac
}

#
# SAFE COMMAND EXECUTION
#

# Safe command execution (alternative to eval)
# @param {string} command - The command to execute
# @returns {int} Exit code of the command
safe_execute() {
    local cmd_string="$1"
    
    if [ -z "$cmd_string" ]; then
        log_error "No command provided to safe_execute"
        return $SECURITY_ERROR_PARAMETER
    fi
    
    # Define allowed commands whitelist
    local allowed_commands=("gs" "cp" "mv" "rm" "mkdir" "chmod" "touch" "find" "grep" "awk" "sed" "cat" "tail" "head" "stat" "dd" "file" "identify")
    
    # Extract the command (first word before any spaces)
    local cmd="${cmd_string%% *}"
    
    # Check if the command is in the whitelist
    local allowed=false
    for allowed_cmd in "${allowed_commands[@]}"; do
        if [ "$cmd" = "$allowed_cmd" ]; then
            allowed=true
            break
        fi
    done
    
    if ! $allowed; then
        log_error "Command '$cmd' is not in the allowed commands list"
        return $SECURITY_ERROR_COMMAND_INJECTION
    fi
    
    # Log the command being executed
    log_debug "Executing command: $cmd_string"
    
    # Use an array to properly handle arguments with spaces
    local cmd_array=()
    read -ra cmd_array <<< "$cmd_string"
    
    # Execute the command with its arguments
    "${cmd_array[@]}"
    return $?
}

#
# SECURE FILE OPERATIONS
#

# Safe file operations with permission checks
# @param {string} file - Path to the file
# @param {string} content - Content to write
# @param {string} perms - File permissions (default 0600)
# @returns {int} 0 on success, non-zero on error
safe_write_file() {
    local file="$1"
    local content="$2"
    local perms="${3:-0600}"  # Default to secure permissions
    
    # Validate path
    local safe_file
    safe_file=$(safe_path "$file")
    if [ $? -ne 0 ]; then
        return $SECURITY_ERROR_PATH_TRAVERSAL
    fi
    
    # Ensure parent directory exists
    local dir
    dir=$(dirname "$safe_file")
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || {
            log_error "Failed to create directory: $dir"
            return $SECURITY_ERROR_PERMISSION
        }
    fi
    
    # Check write permissions on parent directory
    if [ ! -w "$dir" ]; then
        log_error "No write permission to directory: $dir"
        return $SECURITY_ERROR_PERMISSION
    fi
    
    # Create a temporary file with secure permissions
    local temp_file
    temp_file=$(secure_tempfile "write")
    if [ $? -ne 0 ] || [ -z "$temp_file" ]; then
        log_error "Failed to create temporary file for writing"
        return $SECURITY_ERROR_GENERAL
    fi
    
    # Write content to temp file
    echo "$content" > "$temp_file" || {
        log_error "Failed to write to temporary file"
        rm -f "$temp_file"
        return $SECURITY_ERROR_GENERAL
    }
    
    # Set permissions on temp file
    chmod "$perms" "$temp_file" || {
        log_error "Failed to set permissions on temporary file"
        rm -f "$temp_file"
        return $SECURITY_ERROR_PERMISSION
    }
    
    # Move temp file to final location (atomic operation)
    mv "$temp_file" "$safe_file" || {
        log_error "Failed to move temporary file to destination: $safe_file"
        rm -f "$temp_file"
        return $SECURITY_ERROR_GENERAL
    }
    
    return $SECURITY_SUCCESS
}

# Secure temporary file creation
# @param {string} prefix - Optional prefix for temp filename
# @returns {string} Path to temporary file or empty on failure
secure_tempfile() {
    local prefix="${1:-compresskit}"
    local tempdir="${TMPDIR:-/tmp}"
    
    # Ensure temp directory exists and is writable
    if [ ! -d "$tempdir" ] || [ ! -w "$tempdir" ]; then
        log_error "Temp directory not available or not writable: $tempdir"
        return $SECURITY_ERROR_PERMISSION
    fi
    
    # Secure the temp directory from exploitation
    local secure_tempdir="${tempdir}/compresskit_secure"
    
    # Create secure temp subdirectory if it doesn't exist
    if [ ! -d "$secure_tempdir" ]; then
        mkdir -p "$secure_tempdir" || {
            log_error "Failed to create secure temp directory"
            return $SECURITY_ERROR_PERMISSION
        }
        chmod 700 "$secure_tempdir" || {
            log_error "Failed to set permissions on secure temp directory"
            return $SECURITY_ERROR_PERMISSION
        }
    fi
    
    # Create a unique filename with mktemp (more secure than self-made solutions)
    local tempfile
    tempfile=$(mktemp "${secure_tempdir}/${prefix}.XXXXXXXX") || {
        log_error "Failed to create temporary file"
        return $SECURITY_ERROR_GENERAL
    }
    
    # Set secure permissions
    chmod 600 "$tempfile" || {
        log_error "Failed to set permissions on temporary file"
        rm -f "$tempfile"
        return $SECURITY_ERROR_PERMISSION
    }
    
    echo "$tempfile"
    return $SECURITY_SUCCESS
}

#
# INPUT VALIDATION
#

# Validate input parameters against allowed values
# @param {string} input - Input value to validate
# @param {string...} allowed - List of allowed values
# @returns {int} 0 if valid, 1 if invalid
validate_input() {
    local input="$1"
    shift
    
    if [ -z "$input" ]; then
        log_error "Empty input provided for validation"
        return $SECURITY_ERROR_PARAMETER
    fi
    
    local valid=false
    for allowed in "$@"; do
        if [ "$input" = "$allowed" ]; then
            valid=true
            break
        fi
    done
    
    if ! $valid; then
        log_error "Invalid input '$input'. Allowed values: $*"
        return $SECURITY_ERROR_VALIDATION
    fi
    
    return $SECURITY_SUCCESS
}

# Validate numeric input within range
# @param {string} input - Input value to validate
# @param {int} min - Minimum allowed value (optional)
# @param {int} max - Maximum allowed value (optional)
# @returns {int} 0 if valid, 1 if invalid
validate_numeric() {
    local input="$1"
    local min="$2"
    local max="$3"
    
    # Check if input is a number
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        log_error "Input must be a positive integer: $input"
        return $SECURITY_ERROR_VALIDATION
    fi
    
    # Check minimum value if specified
    if [ -n "$min" ] && [ "$input" -lt "$min" ]; then
        log_error "Value must be at least $min: $input"
        return $SECURITY_ERROR_VALIDATION
    fi
    
    # Check maximum value if specified
    if [ -n "$max" ] && [ "$input" -gt "$max" ]; then
        log_error "Value must be at most $max: $input"
        return $SECURITY_ERROR_VALIDATION
    }
    
    return $SECURITY_SUCCESS
}

# Sanitize string to prevent injection attacks
# @param {string} input - String to sanitize
# @returns {string} Sanitized string
sanitize_string() {
    local input="$1"
    
    # Remove dangerous characters, allow only alphanumeric, spaces and basic punctuation
    local sanitized
    sanitized="${input//[^a-zA-Z0-9 _.,:;?!@#%^*()\[\]{}+=\/-]/}"
    
    # Remove potential command execution characters
    sanitized="${sanitized//\`/}"
    sanitized="${sanitized//\$/}"
    sanitized="${sanitized//\\/}"
    
    echo "$sanitized"
}

# Safe email sending (to replace unsafe mail command usage)
# @param {string} recipient - Email recipient
# @param {string} subject - Email subject
# @param {string} message - Email message
# @returns {int} Exit code of mail command
safe_send_email() {
    local recipient="$1"
    local subject="$2"
    local message="$3"
    
    # Validate email format (basic check)
    if [[ ! "$recipient" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        log_error "Invalid email format: $recipient"
        return $SECURITY_ERROR_VALIDATION
    fi
    
    # Sanitize inputs before passing to mail command
    subject=$(sanitize_string "$subject")
    
    # Use a secure temp file for the message body instead of piping directly
    local tempfile
    tempfile=$(secure_tempfile "email")
    
    if [ $? -ne 0 ]; then
        return $SECURITY_ERROR_GENERAL
    fi
    
    echo "$message" > "$tempfile"
    
    # Send email using the message from the temp file
    mail -s "$subject" "$recipient" < "$tempfile"
    local status=$?
    
    # Clean up
    rm -f "$tempfile"
    
    return $status
}

# Check file permissions
# @param {string} file - Path to file
# @param {string} required_perms - Required permissions (e.g., "600")
# @returns {int} 0 if permissions match or are more restrictive, 1 otherwise
check_file_permissions() {
    local file="$1"
    local required_perms="$2"
    
    # Validate file
    if [ ! -f "$file" ]; then
        log_error "File does not exist: $file"
        return $SECURITY_ERROR_GENERAL
    fi
    
    # Get file permissions
    local actual_perms
    actual_perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%Lp" "$file" 2>/dev/null)
    
    if [ -z "$actual_perms" ]; then
        log_error "Failed to get permissions for: $file"
        return $SECURITY_ERROR_GENERAL
    fi
    
    # Compare permissions - ensuring actual perms are same or more restrictive
    # This is a simple comparison, would need to be expanded for detailed perm checks
    if [ "$actual_perms" -le "$required_perms" ]; then
        return $SECURITY_SUCCESS
    else
        log_warning "File has insecure permissions: $file ($actual_perms > $required_perms)"
        return $SECURITY_ERROR_PERMISSION
    fi
}

# Reports security incidents
# @param {string} incident_type - Type of incident
# @param {string} details - Incident details
# @returns {int} 0 on success, non-zero on error
report_security_incident() {
    local incident_type="$1"
    local details="$2"
    local report_file
    local timestamp=$(date "+%Y%m%d_%H%M%S")
    
    # Create a secure path for the report
    report_file=$(safe_path "${HOME}/.config/compresskit/security/incident_${timestamp}.log")
    
    if [ $? -ne 0 ]; then
        log_error "Failed to create security incident report path"
        return $SECURITY_ERROR_GENERAL
    fi
    
    # Ensure directory exists
    local report_dir
    report_dir=$(dirname "$report_file")
    
    if [ ! -d "$report_dir" ]; then
        mkdir -p "$report_dir" || {
            log_error "Failed to create security incident report directory"
            return $SECURITY_ERROR_PERMISSION
        }
        chmod 700 "$report_dir"
    fi
    
    # Create the report
    {
        echo "====== SECURITY INCIDENT REPORT ======"
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "Incident Type: $incident_type"
        echo "User: $(id -un 2>/dev/null || echo 'unknown')"
        echo "Host: $(hostname 2>/dev/null || echo 'unknown')"
        echo "Working Directory: $PWD"
        echo "Command: $0 $*"
        echo "Details: $details"
        echo "====================================="
    } > "$report_file"
    
    # Set secure permissions
    chmod 600 "$report_file"
    
    log_warning "Security incident reported: $incident_type"
    
    # Try to notify admin if email function is available
    if command -v safe_send_email &>/dev/null; then
        local admin_email="admin@example.com"
        
        # Try to get admin email from config if available
        if command -v get_config &>/dev/null; then
            admin_email=$(get_config "admin_email" "admin@example.com")
        fi
        
        safe_send_email "$admin_email" "SECURITY ALERT: $incident_type" "$(cat "$report_file")" || {
            log_warning "Failed to send security notification email"
        }
    fi
    
    return $SECURITY_SUCCESS
}

# Initialize security module
# @returns {int} 0 on success, non-zero on error
init_security_module() {
    log_info "Initializing security module"
    
    # Ensure temporary directory exists
    local tempdir="${TMPDIR:-/tmp}/compresskit_secure"
    mkdir -p "$tempdir" 2>/dev/null && chmod 700 "$tempdir" 2>/dev/null
    
    # Create security incident directory
    local incident_dir="${HOME}/.config/compresskit/security"
    mkdir -p "$incident_dir" 2>/dev/null && chmod 700 "$incident_dir" 2>/dev/null
    
    # Check for security vulnerabilities in the environment
    check_security_vulnerabilities
    
    return $SECURITY_SUCCESS
}

# Check for common security vulnerabilities in the environment
# @returns {int} 0 if environment is secure, non-zero otherwise
check_security_vulnerabilities() {
    log_debug "Checking environment for security vulnerabilities"
    
    # Check if running as root
    if [ "$(id -u)" -eq 0 ]; then
        log_warning "Running as root is not recommended for security reasons"
    fi
    
    # Check umask
    local current_umask
    current_umask=$(umask)
    if [ "$current_umask" != "0022" ] && [ "$current_umask" != "0027" ] && [ "$current_umask" != "0077" ]; then
        log_warning "Unusual umask setting detected: $current_umask"
    fi
    
    return $SECURITY_SUCCESS
}

# Run initialization when this script is sourced
init_security_module
