#!/data/data/com.termux/files/usr/bin/bash

# Secure Utilities Module for CompressKit
# Provides secure wrappers and utility functions to prevent security vulnerabilities

# Safe command execution (alternative to eval)
# Usage: safe_execute "command with args"
safe_execute() {
    if [ -z "$1" ]; then
        echo "Error: No command provided to safe_execute" >&2
        return 1
    fi
    
    # Define allowed commands whitelist
    local allowed_commands=("gs" "cp" "mv" "rm" "mkdir" "chmod" "touch" "find" "grep" "awk" "sed" "cat" "tail" "head")
    
    # Extract the command (first word before any spaces)
    local cmd="${1%% *}"
    
    # Check if the command is in the whitelist
    local allowed=false
    for allowed_cmd in "${allowed_commands[@]}"; do
        if [ "$cmd" = "$allowed_cmd" ]; then
            allowed=true
            break
        fi
    done
    
    if ! $allowed; then
        echo "Error: Command '$cmd' is not in the allowed commands list" >&2
        return 1
    fi
    
    # Use an array to properly handle arguments with spaces
    local cmd_array=()
    read -ra cmd_array <<< "$1"
    
    # Execute the command with its arguments
    "${cmd_array[@]}"
    return $?
}

# Validate and sanitize a file path to prevent path traversal
# Usage: safe_path "/path/to/file"
safe_path() {
    local path="$1"
    local safety_level="${2:-strict}"
    
    # Reject empty paths
    if [ -z "$path" ]; then
        echo "Error: Empty path provided" >&2
        return 1
    fi
    
    # Validate safety level
    if ! validate_path_safety_level "$safety_level"; then
        return 1
    fi
    
    # Remove any null bytes (potential exploit vector)
    path="${path//$'\0'/}"
    
    # Enhanced path traversal protection
    # Check for relative path components that could be used for traversal
    if [[ "$path" == *".."* || "$path" =~ (/\./)|(/\.$) ]]; then
        echo "Error: Path contains forbidden traversal components: $path" >&2
        return 1
    fi
    
    # Normalize path using realpath if available
    local resolved_path
    if command -v realpath &>/dev/null; then
        resolved_path=$(realpath -s "$path" 2>/dev/null)
        if [ $? -ne 0 ]; then
            echo "Error: Failed to resolve path: $path" >&2
            return 1
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
            if [[ "$resolved_path" == *"/etc"* || "$resolved_path" == *"/bin"* || "$resolved_path" == *"/sbin"* ]]; then
                # Check if the path is a symlink
                if [ -L "$resolved_path" ]; then
                    echo "Error: Security restriction - symlinks not allowed in sensitive directories: $resolved_path" >&2
                    return 1
                fi
            fi
            ;;
        "normal")
            # Less restrictive checks for normal mode
            ;;
        "relaxed")
            # Minimal checks for relaxed mode
            ;;
    esac
    
    echo "$resolved_path"
    return 0
}

# Validate path safety level
validate_path_safety_level() {
    local level="$1"
    
    # Check if the level is valid
    case "$level" in
        "strict"|"normal"|"relaxed") 
            return 0 
            ;;
        *)
            echo "Error: Invalid path safety level: $level" >&2
            echo "Valid options are: strict, normal, relaxed" >&2
            return 1
            ;;
    esac
}

# Safe file operations with permission checks
# Usage: safe_write_file "/path/to/file" "content" "permissions"
safe_write_file() {
    local file="$1"
    local content="$2"
    local perms="${3:-0600}"  # Default to secure permissions
    
    # Validate path
    local safe_file
    safe_file=$(safe_path "$file")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Ensure parent directory exists
    local dir
    dir=$(dirname "$safe_file")
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || {
            echo "Error: Failed to create directory: $dir" >&2
            return 1
        }
    fi
    
    # Check write permissions on parent directory
    if [ ! -w "$dir" ]; then
        echo "Error: No write permission to directory: $dir" >&2
        return 1
    fi
    
    # Write content to file
    echo "$content" > "$safe_file" || {
        echo "Error: Failed to write to file: $safe_file" >&2
        return 1
    }
    
    # Set permissions
    chmod "$perms" "$safe_file" || {
        echo "Error: Failed to set permissions on: $safe_file" >&2
        return 1
    }
    
    return 0
}

# Secure temporary file creation
# Usage: secure_tempfile "prefix"
secure_tempfile() {
    local prefix="${1:-compresskit}"
    local tempdir="${TMPDIR:-/tmp}"
    
    # Ensure temp directory exists and is writable
    if [ ! -d "$tempdir" ] || [ ! -w "$tempdir" ]; then
        echo "Error: Temp directory not available or not writable: $tempdir" >&2
        return 1
    }
    
    # Create a unique filename with mktemp (more secure than self-made solutions)
    local tempfile
    tempfile=$(mktemp "$tempdir/${prefix}.XXXXXXXX") || {
        echo "Error: Failed to create temporary file" >&2
        return 1
    }
    
    # Set secure permissions
    chmod 600 "$tempfile" || {
        echo "Error: Failed to set permissions on temporary file" >&2
        rm -f "$tempfile"
        return 1
    }
    
    echo "$tempfile"
    return 0
}

# Validate input parameters against allowed values
# Usage: validate_input "value" "allowed_value1" "allowed_value2" ...
validate_input() {
    local input="$1"
    shift
    
    if [ -z "$input" ]; then
        echo "Error: Empty input provided for validation" >&2
        return 1
    fi
    
    local valid=false
    for allowed in "$@"; do
        if [ "$input" = "$allowed" ]; then
            valid=true
            break
        fi
    done
    
    if ! $valid; then
        echo "Error: Invalid input '$input'. Allowed values: $*" >&2
        return 1
    fi
    
    return 0
}

# Safe email sending (to replace unsafe mail command usage)
# Usage: safe_send_email "recipient" "subject" "message"
safe_send_email() {
    local recipient="$1"
    local subject="$2"
    local message="$3"
    
    # Validate email format (basic check)
    if [[ ! "$recipient" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        echo "Error: Invalid email format: $recipient" >&2
        return 1
    fi
    
    # Sanitize inputs before passing to mail command
    subject="${subject//\`/}"
    subject="${subject//\$/}"
    subject="${subject//\"/}"
    
    # Use a secure temp file for the message body instead of piping directly
    local tempfile
    tempfile=$(secure_tempfile "email")
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo "$message" > "$tempfile"
    
    # Send email using the message from the temp file
    mail -s "$subject" "$recipient" < "$tempfile"
    local status=$?
    
    # Clean up
    rm -f "$tempfile"
    
    return $status
}

# Consistent error handling function
# Usage: handle_security_error "error_code" "error_message" "function_name"
handle_security_error() {
    local error_code=$1
    local error_message="$2"
    local function_name="$3"
    
    # Log the error
    if command -v log_error &>/dev/null; then
        log_error "[Security] $function_name: $error_message (code: $error_code)"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] [Security] $function_name: $error_message (code: $error_code)" >&2
    fi
    
    return $error_code
}

# Sanitize string to prevent injection attacks
# Usage: sanitize_string "input_string"
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
