#!/bin/bash

### Myth-Driven PDF Compression Script ###
# Engraving recursive logic into silicon, optimized for structure, aesthetics, and performance.

# Function: Compress a single PDF
compress_pdf() {
    local input_file="$1"
    local quality="$2"
    local output_dir="$3"

    # Ensure Ghostscript is installed
    if ! command -v gs &> /dev/null; then
        echo "Error: Ghostscript is not installed." >&2
        exit 1
    fi

    # Define the output file path
    local output_file="${output_dir}/$(basename "$input_file" .pdf)_compressed.pdf"

    # Map quality levels to Ghostscript settings
    local quality_setting
    case "$quality" in
        high) quality_setting="/printer";;
        medium) quality_setting="/ebook";;
        low) quality_setting="/screen";;
        *) quality_setting="/default";;
    esac

    # Compress the PDF using Ghostscript
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS="$quality_setting" \
       -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$output_file" "$input_file"

    if [ $? -eq 0 ]; then
        echo "Compression successful: ${output_file}"
    else
        echo "Error compressing file: ${input_file}" >&2
        exit 1
    fi
}

# Function: Recursively compress PDFs in a directory
compress_directory() {
    local input_dir="$1"
    local quality="$2"
    local output_dir="$3"

    # Traverse the directory tree, finding all PDFs
    find "$input_dir" -type f -name "*.pdf" | while read -r pdf; do
        # Recreate the directory structure in the output
        local relative_path="${pdf#$input_dir/}"
        local target_dir="${output_dir}/$(dirname "$relative_path")"
        
        mkdir -p "$target_dir"
        compress_pdf "$pdf" "$quality" "$target_dir"
    done
}

# Function: Main entry point
main() {
    # Validate input parameters
    if [ $# -lt 3 ]; then
        echo "Usage: $0 <input_file_or_dir> <quality: high|medium|low> <output_dir>" >&2
        exit 1
    fi

    local input="$1"
    local quality="$2"
    local output_dir="$3"

    # Check if input exists
    if [ ! -e "$input" ]; then
        echo "Error: Input file or directory does not exist." >&2
        exit 1
    fi

    # Create the output directory if it doesn't exist
    mkdir -p "$output_dir"

    # Determine if input is a file or directory
    if [ -f "$input" ]; then
        compress_pdf "$input" "$quality" "$output_dir"
    elif [ -d "$input" ]; then
        compress_directory "$input" "$quality" "$output_dir"
    else
        echo "Error: Unsupported input type." >&2
        exit 1
    fi
}

# Initiate the recursive compression process
main "$@"
