#!/data/data/com.termux/files/usr/bin/bash

# Input Validation Module for CompressKit
# Provides comprehensive input validation functions for user-facing interfaces

# Import secure utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/secure_utils.sh"

# Error codes
VALIDATION_SUCCESS=0
VALIDATION_ERROR=1
VALIDATION_WARNING=2

# Display validation error
validation_error() {
    local message="$1"
    
    # Use UI error function if available
    if command -v ui_error &>/dev/null; then
        ui_error "$message"
    else
        echo -e "\033[1;31mValidation Error:\033[0m $message" >&2
    fi
    
    # Log error if logging available
    if command -v log_error &>/dev/null; then
        log_error "Validation: $message"
    fi
    
    return $VALIDATION_ERROR
}

# Display validation warning
validation_warning() {
    local message="$1"
    
    # Use UI warning function if available
    if command -v ui_warning &>/dev/null; then
        ui_warning "$message"
    else
        echo -e "\033[1;33mValidation Warning:\033[0m $message" >&2
    fi
    
    # Log warning if logging available
    if command -v log_warning &>/dev/null; then
        log_warning "Validation: $message"
    fi
    
    return $VALIDATION_WARNING
}

# Validate file existence and readability
# Usage: validate_readable_file "/path/to/file"
validate_readable_file() {
    local file_path="$1"
    
    # Validate and sanitize path
    local safe_path
    safe_path=$(safe_path "$file_path" "strict")
    if [ $? -ne 0 ] || [ -z "$safe_path" ]; then
        validation_error "Invalid file path: $file_path"
        return $VALIDATION_ERROR
    fi
    
    # Check file existence
    if [ ! -e "$safe_path" ]; then
        validation_error "File does not exist: $safe_path"
        return $VALIDATION_ERROR
    fi
    
    # Check if it's a regular file
    if [ ! -f "$safe_path" ]; then
        validation_error "Not a regular file: $safe_path"
        return $VALIDATION_ERROR
    fi
    
    # Check if file is readable
    if [ ! -r "$safe_path" ]; then
        validation_error "File is not readable: $safe_path"
        return $VALIDATION_ERROR
    fi
    
    # Check file size (warn if empty)
    if [ ! -s "$safe_path" ]; then
        validation_warning "File is empty: $safe_path"
        return $VALIDATION_WARNING
    fi
    
    return $VALIDATION_SUCCESS
}

# Validate writable directory
# Usage: validate_writable_dir "/path/to/directory"
validate_writable_dir() {
    local dir_path="$1"
    local create_if_missing="${2:-false}"
    
    # Validate and sanitize path
    local safe_path
    safe_path=$(safe_path "$dir_path" "strict")
    if [ $? -ne 0 ] || [ -z "$safe_path" ]; then
        validation_error "Invalid directory path: $dir_path"
        return $VALIDATION_ERROR
    fi
    
    # Check if directory exists
    if [ ! -d "$safe_path" ]; then
        if [ "$create_if_missing" = "true" ]; then
            # Try to create the directory
            mkdir -p "$safe_path" 2>/dev/null
            if [ $? -ne 0 ]; then
                validation_error "Could not create directory: $safe_path"
                return $VALIDATION_ERROR
            fi
        else
            validation_error "Directory does not exist: $safe_path"
            return $VALIDATION_ERROR
        fi
    fi
    
    # Check if directory is writable
    if [ ! -w "$safe_path" ]; then
        validation_error "Directory is not writable: $safe_path"
        return $VALIDATION_ERROR
    fi
    
    return $VALIDATION_SUCCESS
}

# Validate file extension
# Usage: validate_file_extension "/path/to/file" "pdf" "doc" "txt"
validate_file_extension() {
    local file_path="$1"
    shift
    local valid_extensions=("$@")
    
    # Get file extension (lowercase)
    local ext
    ext=$(echo "${file_path##*.}" | tr '[:upper:]' '[:lower:]')
    
    # Check if extension is in allowed list
    local valid=false
    for valid_ext in "${valid_extensions[@]}"; do
        if [ "$ext" = "$valid_ext" ]; then
            valid=true
            break
        fi
    done
    
    if ! $valid; then
        validation_error "Invalid file extension .$ext. Allowed: ${valid_extensions[*]}"
        return $VALIDATION_ERROR
    fi
    
    return $VALIDATION_SUCCESS
}

# Validate numeric input
# Usage: validate_numeric "42" [min] [max]
validate_numeric() {
    local input="$1"
    local min="$2"
    local max="$3"
    
    # Check if input is a number
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        validation_error "Input must be a positive integer: $input"
        return $VALIDATION_ERROR
    fi
    
    # Check minimum value if specified
    if [ -n "$min" ] && [ "$input" -lt "$min" ]; then
        validation_error "Value must be at least $min: $input"
        return $VALIDATION_ERROR
    fi
    
    # Check maximum value if specified
    if [ -n "$max" ] && [ "$input" -gt "$max" ]; then
        validation_error "Value must be at most $max: $input"
        return $VALIDATION_ERROR
    fi
    
    return $VALIDATION_SUCCESS
}

# Validate email address
# Usage: validate_email "user@example.com"
validate_email() {
    local email="$1"
    
    # Simple regex for email validation
    if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        validation_error "Invalid email address format: $email"
        return $VALIDATION_ERROR
    fi
    
    return $VALIDATION_SUCCESS
}

# Validate PDF file
# Usage: validate_pdf "/path/to/file.pdf"
validate_pdf() {
    local file_path="$1"
    
    # First check if it's a readable file
    validate_readable_file "$file_path"
    if [ $? -ne 0 ]; then
        return $VALIDATION_ERROR
    fi
    
    # Check extension
    validate_file_extension "$file_path" "pdf"
    if [ $? -ne 0 ]; then
        return $VALIDATION_ERROR
    fi
    
    # Check file header for PDF signature
    local file_header
    file_header=$(head -c 4 "$file_path" 2>/dev/null | tr -d '\0')
    
    if [ "$file_header" != "%PDF" ]; then
        validation_error "File is not a valid PDF (missing PDF header): $file_path"
        return $VALIDATION_ERROR
    fi
    
    # Additional PDF validation if pdfinfo is available
    if command -v pdfinfo &>/dev/null; then
        if ! pdfinfo "$file_path" &>/dev/null; then
            validation_error "File appears to be a corrupt PDF: $file_path"
            return $VALIDATION_ERROR
        fi
    fi
    
    return $VALIDATION_SUCCESS
}

# Validate compression quality
# Usage: validate_compression_quality "medium"
validate_compression_quality() {
    local quality="$1"
    
    # Validate against allowed values
    validate_input "$quality" "high" "medium" "low" "ultra"
    if [ $? -ne 0 ]; then
        validation_error "Invalid quality level. Must be 'high', 'medium', 'low' or 'ultra'"
        return $VALIDATION_ERROR
    fi
    
    # Additional check for "ultra" quality which requires license
    if [ "$quality" = "ultra" ] && command -v is_feature_licensed &>/dev/null; then
        if ! is_feature_licensed "ultra_compression"; then
            validation_error "Ultra compression requires a premium license"
            return $VALIDATION_ERROR
        fi
    fi
    
    return $VALIDATION_SUCCESS
}

# Validate command-line arguments for compression
# Usage: validate_compression_args "/path/to/file.pdf" "medium" "/output/directory"
validate_compression_args() {
    local input_file="$1"
    local quality="$2"
    local output_dir="$3"
    
    # Validate input file
    validate_pdf "$input_file"
    if [ $? -ne 0 ]; then
        return $VALIDATION_ERROR
    fi
    
    # Validate quality
    validate_compression_quality "$quality"
    if [ $? -ne 0 ]; then
        return $VALIDATION_ERROR
    fi
    
    # Validate output directory
    validate_writable_dir "$output_dir" "true"
    if [ $? -ne 0 ]; then
        return $VALIDATION_ERROR
    fi
    
    return $VALIDATION_SUCCESS
}

# Example usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Running as a script
    echo "CompressKit Input Validation Module"
    echo "=================================="
    
    # Simple test cases
    echo -e "\nTesting file validation:"
    validate_readable_file "/etc/hosts" && echo "Valid file" || echo "Invalid file"
    
    echo -e "\nTesting directory validation:"
    validate_writable_dir "/tmp" && echo "Valid directory" || echo "Invalid directory"
    
    echo -e "\nTesting numeric validation:"
    validate_numeric "42" 1 100 && echo "Valid number" || echo "Invalid number"
    validate_numeric "abc" && echo "Valid number" || echo "Invalid number"
    
    echo -e "\nTesting email validation:"
    validate_email "user@example.com" && echo "Valid email" || echo "Invalid email"
    validate_email "invalid-email" && echo "Valid email" || echo "Invalid email"
    
    echo
    echo "Use 'source $(basename "$0")' to import these functions"
fi
