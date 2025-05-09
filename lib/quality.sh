#!/data/data/com.termux/files/usr/bin/bash

get_quality_settings() {
    local quality="$1"
    case "$quality" in
        "high")
            echo "-dPDFSETTINGS=/prepress \\
                 -dColorImageResolution=300 \\
                 -dCompatibilityLevel=1.5 \\
                 -dDownsampleColorImages=false"
            ;;
        "medium")
            echo "-dPDFSETTINGS=/ebook \\
                 -dColorImageResolution=150 \\
                 -dCompatibilityLevel=1.4 \\
                 -dDownsampleColorImages=true \\
                 -dColorImageDownsampleType=/Bicubic"
            ;;
        "low")
            echo "-dPDFSETTINGS=/screen \\
                 -dColorImageResolution=72 \\
                 -dCompatibilityLevel=1.4 \\
                 -dDownsampleColorImages=true \\
                 -dColorImageDownsampleType=/Subsample \\
                 -dEmbedAllFonts=false"
            ;;
        *)
            echo "Error: Unsupported quality level '$quality'. Use 'high', 'medium', or 'low'."
            exit 1
            ;;
    esac
}

validate_quality() {
    local quality="$1"
    case "$quality" in
        "high"|"medium"|"low") return 0 ;;
        *)
            echo "Error: Invalid quality level '$quality'. Valid options are 'high', 'medium', or 'low'."
            return 1
            ;;
    esac
}

# Example usage:
# validate_quality "$1" && get_quality_settings "$1" || exit 1
