#!/data/data/com.termux/files/usr/bin/bash

# Universal error handler
error() {
    echo -e "\033[31mError: $1\033[0m" >&2
    return 1
}

# Get file size in bytes
get_file_size() {
    local file="$1"
    if [ ! -f "$file" ]; then
        error "File not found: $file"
        return 1
    fi
    stat --format="%s" "$file" 2>/dev/null || ls -l "$file" | awk '{print $5}'
}

# Format size to human-readable
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

# Recursive PDF info
show_pdf_info_recursive() {
    local dir="$1"
    if [ -d "$dir" ]; then
        echo "Processing directory: $dir"
        find "$dir" -type f -name "*.pdf" | while read -r file; do
            show_pdf_info "$file"
        done
    else
        show_pdf_info "$dir"
    fi
}

# Show PDF information
show_pdf_info() {
    local file="$1"
    if [ ! -f "$file" ]; then
        error "File not found: $file"
        return 1
    fi

    echo -e "📄 PDF Information\n=================="
    echo "Filename: $(basename "$file")"
    echo "Size: $(format_size $(get_file_size "$file"))"

    if command -v pdfinfo >/dev/null 2>&1; then
        echo
        pdfinfo "$file" | grep -E "Pages|PDF version|Page size|File size|Creator|Producer"
    else
        echo "pdfinfo command not available. Install it for detailed insights."
    fi
}

# Entrypoint
if [ $# -eq 0 ]; then
    error "No arguments provided. Usage: $0 <file_or_directory>"
    exit 1
fi

show_pdf_info_recursive "$1"
