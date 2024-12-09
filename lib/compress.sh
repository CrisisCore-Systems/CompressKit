#!/data/data/com.termux/files/usr/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/file_ops.sh"
source "${SCRIPT_DIR}/quality.sh"

compress_pdf() {
    local input_file="$1"
    local quality="${2:-medium}"
    local output_file="${3:-${input_file%.*}_compressed.pdf}"
    local verbose="${4:-0}"
    
    # Validate input
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file not found: $input_file"
        return 1
    fi
    
    # Get original size
    local original_size=$(get_file_size "$input_file")
    [ "$verbose" -eq 1 ] && echo "Original size: $(format_size $original_size)"
    
    # Get quality settings
    local settings=$(get_quality_settings "$quality")
    [ "$verbose" -eq 1 ] && echo "Using quality settings: $quality"
    
    # Compress PDF
    if ! gs -q -dNOPAUSE -dBATCH -dSAFER \
          -sDEVICE=pdfwrite \
          $settings \
          -sOutputFile="$output_file" \
          "$input_file" 2>/dev/null; then
        echo "Error: Compression failed"
        return 1
    fi
    
    # Get compressed size
    local compressed_size=$(get_file_size "$output_file")
    local saved=$((original_size - compressed_size))
    local percent=$(( (saved * 100) / original_size ))
    
    echo "Compression complete:"
    echo "- Input: $(format_size $original_size)"
    echo "- Output: $(format_size $compressed_size)"
    echo "- Saved: ${percent}%"
    echo "- File: $output_file"
    
    return 0
}
