#!/data/data/com.termux/files/usr/bin/bash

### Myth-Driven PDF Compression Script ###
# Engraving recursive logic into silicon, optimized for structure, aesthetics, and performance.

# Import secure utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/secure_utils.sh"
source "${SCRIPT_DIR}/license_verifier.sh"

# SECURITY IMPROVEMENT: Import quality settings and safe execution modules
if [ -f "${SCRIPT_DIR}/quality_settings.sh" ]; then
    source "${SCRIPT_DIR}/quality_settings.sh"
fi
if [ -f "${SCRIPT_DIR}/safe_execute.sh" ]; then
    source "${SCRIPT_DIR}/safe_execute.sh"
fi

# Function: Compress a single PDF
compress_pdf() {
    local input_file="$1"
    local quality="$2"
    local output_dir="$3"

    # SECURITY FIX: Validate and sanitize paths
    local safe_input_file
    safe_input_file=$(safe_path "$input_file")
    if [ $? -ne 0 ] || [ -z "$safe_input_file" ]; then
        echo "Error: Invalid input file path" >&2
        return 1
    fi
    
    local safe_output_dir
    safe_output_dir=$(safe_path "$output_dir")
    if [ $? -ne 0 ] || [ -z "$safe_output_dir" ]; then
        echo "Error: Invalid output directory path" >&2
        return 1
    fi

    # SECURITY FIX: Validate quality parameter
    if ! validate_input "$quality" "high" "medium" "low" "ultra"; then
        echo "Error: Invalid quality level. Must be 'high', 'medium', 'low', or 'ultra'" >&2
        return 1
    fi
    
    # Check license for ultra quality
    if [ "$quality" = "ultra" ]; then
        if ! is_feature_licensed "ultra_compression"; then
            echo "Error: Ultra compression requires a valid license" >&2
            return 1
        fi
    fi

    # Ensure Ghostscript is installed
    if ! command -v gs &> /dev/null; then
        echo "Error: Ghostscript is not installed." >&2
        return 1
    fi

    # Define the output file path with sanitized paths
    local output_file="${safe_output_dir}/$(basename "$safe_input_file" .pdf)_compressed.pdf"

    # SECURITY IMPROVEMENT: Use quality settings module if available
    local quality_setting
    if type get_quality_setting &>/dev/null; then
        quality_setting=$(get_quality_setting "$quality" "pdf")
    else
        # Fallback to inline mapping if module not available
        case "$quality" in
            ultra) quality_setting="/prepress" ;;
            high) quality_setting="/printer" ;;
            medium) quality_setting="/ebook" ;;
            low) quality_setting="/screen" ;;
        esac
    fi

    # SECURITY FIX: Create a temporary file for processing
    local temp_output
    temp_output=$(secure_tempfile "compress")
    if [ $? -ne 0 ] || [ -z "$temp_output" ]; then
        echo "Error: Failed to create temporary file" >&2
        return 1
    fi
    
    # Check if input file exists and is readable
    if [ ! -f "$safe_input_file" ]; then
        echo "Error: Input file does not exist: $safe_input_file" >&2
        rm -f "$temp_output"
        return 1
    fi
    
    if [ ! -r "$safe_input_file" ]; then
        echo "Error: Cannot read input file: $safe_input_file" >&2
        rm -f "$temp_output"
        return 1
    fi
    
    # Create output directory if it doesn't exist
    if [ ! -d "$safe_output_dir" ]; then
        mkdir -p "$safe_output_dir" || {
            echo "Error: Failed to create output directory: $safe_output_dir" >&2
            rm -f "$temp_output"
            return 1
        }
    fi
    
    # Check if output directory is writable
    if [ ! -w "$safe_output_dir" ]; then
        echo "Error: Output directory is not writable: $safe_output_dir" >&2
        rm -f "$temp_output"
        return 1
    fi
    
    # Performance optimization: Check if file was already compressed recently
    local cache_dir="$HOME/.cache/compresskit"
    local file_hash=$(sha256sum "$safe_input_file" | cut -d' ' -f1)
    local cache_file="${cache_dir}/${file_hash}_${quality}"
    
    if [ -f "$cache_file" ] && [ -f "$(cat "$cache_file")" ]; then
        local cached_output=$(cat "$cache_file")
        # Use cached result if less than a day old
        if [ $(($(date +%s) - $(stat -c %Y "$cached_output"))) -lt 86400 ]; then
            echo "Using cached compression result: ${cached_output}"
            cp "$cached_output" "$output_file"
            return 0
        fi
    fi
    
    # Compress the PDF using Ghostscript with safer execution
    if type safe_execute_array &>/dev/null; then
        safe_execute_array gs "-sDEVICE=pdfwrite" "-dCompatibilityLevel=1.4" \
            "-dPDFSETTINGS=${quality_setting}" "-dNOPAUSE" "-dQUIET" "-dBATCH" \
            "-sOutputFile=${temp_output}" "${safe_input_file}"
        gs_exit_code=$?
    else
        # Fallback to safe_execute if available
        local gs_command="gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=${quality_setting} -dNOPAUSE -dQUIET -dBATCH -sOutputFile=${temp_output} ${safe_input_file}"
        safe_execute "$gs_command"
        gs_exit_code=$?
    fi

    # Check the return code of gs
    if [ $gs_exit_code -ne 0 ]; then
        echo "Error: Ghostscript failed with exit code $gs_exit_code" >&2
        rm -f "$temp_output"
        return 1
    fi

    # Check if temporary file was created and has content
    if [ ! -s "$temp_output" ]; then
        echo "Error: Output file is empty or not created" >&2
        rm -f "$temp_output"
        return 1
    fi

    # Move the temporary file to the final location using safe_execute
    safe_execute "mv $temp_output $output_file"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to move temporary file to output location" >&2
        rm -f "$temp_output"
        return 1
    fi

    # Cache the result
    mkdir -p "$cache_dir"
    echo "$output_file" > "$cache_file"

    # Set appropriate permissions using safe_execute
    safe_execute "chmod 644 $output_file"
    if [ $? -ne 0 ]; then
        echo "Warning: Failed to set permissions on output file" >&2
        # Continue despite permission warning
    fi

    echo "Compression successful: ${output_file}"
    return 0
}

# Function: Recursively compress PDFs in a directory
compress_directory() {
    local input_dir="$1"
    local quality="$2"
    local output_dir="$3"

    # SECURITY FIX: Validate paths
    local safe_input_dir
    safe_input_dir=$(safe_path "$input_dir")
    if [ $? -ne 0 ]; then
        echo "Error: Invalid input directory path" >&2
        return 1
    fi
    
    local safe_output_dir
    safe_output_dir=$(safe_path "$output_dir")
    if [ $? -ne 0 ]; then
        echo "Error: Invalid output directory path" >&2
        return 1
    fi

    # SECURITY IMPROVEMENT: Add additional validation for compression_directory function
    # Use quality settings validation if available
    if type validate_quality_level &>/dev/null; then
        if ! validate_quality_level "$quality"; then
            echo "Error: Invalid quality level: $quality" >&2
            return 1
        fi
    elif ! validate_input "$quality" "high" "medium" "low" "ultra"; then
        echo "Error: Invalid quality level: $quality" >&2
        return 1
    fi

    # Create the output directory with secure permissions
    mkdir -p "$safe_output_dir"
    chmod 755 "$safe_output_dir"

    # Traverse the directory tree, finding all PDFs
    find "$safe_input_dir" -type f -name "*.pdf" | while read -r pdf; do
        # Recreate the directory structure in the output
        local relative_path="${pdf#$safe_input_dir/}"
        local target_dir="${safe_output_dir}/$(dirname "$relative_path")"
        
        mkdir -p "$target_dir"
        chmod 755 "$target_dir"
        compress_pdf "$pdf" "$quality" "$target_dir"
    done
}

# Function: Main entry point
main() {
    # Validate input parameters
    if [ $# -lt 3 ]; then
        echo "Usage: $0 <input_file_or_dir> <quality: high|medium|low> <output_dir>" >&2
        return 1
    fi

    local input="$1"
    local quality="$2"
    local output_dir="$3"

    # SECURITY FIX: Validate and sanitize paths
    local safe_input
    safe_input=$(safe_path "$input")
    if [ $? -ne 0 ]; then
        echo "Error: Invalid input path" >&2
        return 1
    fi
    
    local safe_output_dir
    safe_output_dir=$(safe_path "$output_dir")
    if [ $? -ne 0 ]; then
        echo "Error: Invalid output directory path" >&2
        return 1
    fi

    # Validate input exists
    if [ ! -e "$input" ]; then
        log_error "Input file or directory does not exist: $input"
        return ${ERROR_CODES["FILE_NOT_FOUND"]}
    fi

    # Create the output directory if it doesn't exist
    mkdir -p "$safe_output_dir" || {
        log_error "Failed to create output directory: $safe_output_dir"
        return ${ERROR_CODES["PERMISSION_DENIED"]}
    }
    chmod 755 "$safe_output_dir"

    # Determine if input is a file or directory
    if [ -f "$safe_input" ]; then
        compress_pdf "$safe_input" "$quality" "$safe_output_dir"
        return $?
    elif [ -d "$safe_input" ]; then
        compress_directory "$safe_input" "$quality" "$safe_output_dir"
        return $?
    else {
        log_error "Unsupported input type."
        return ${ERROR_CODES["INVALID_INPUT"]}
    }
}

# Only execute main when script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    # Initialize error handling
    if command -v init_error_handler &>/dev/null; then
        init_error_handler
    fi
    
    main "$@"
    
    # Restore error handling to original state
    if command -v restore_error_handler &>/dev/null; then
        restore_error_handler
    fi
fi
