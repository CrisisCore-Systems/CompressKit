#!/data/data/com.termux/files/usr/bin/bash

# Get file size in bytes
get_file_size() {
    local file="$1"
    ls -l "$file" | awk '{print $5}'
}

# Format size to human readable
format_size() {
    local size="$1"
    if (( size < 1024 )); then
        echo "${size} B"
    elif (( size < 1048576 )); then
        echo "$((size / 1024)) KB"
    else
        echo "$((size / 1048576)) MB"
    fi
}

# Show PDF information
show_pdf_info() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file"
        return 1
    fi

    echo "PDF Information"
    echo "=============="
    echo "Filename: $(basename "$file")"
    echo "Size: $(format_size $(get_file_size "$file"))"
    
    # Use pdfinfo if available
    if command -v pdfinfo >/dev/null 2>&1; then
        echo
        pdfinfo "$file" | grep -E "Pages|PDF version|Page size|File size|Creator|Producer"
    fi
}
