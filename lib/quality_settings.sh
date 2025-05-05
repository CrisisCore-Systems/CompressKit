#!/data/data/com.termux/files/usr/bin/bash

# Quality settings module for CompressKit
# Provides consistent quality levels and settings across all compression operations

# Import dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/secure_utils.sh" ]; then
    source "${SCRIPT_DIR}/secure_utils.sh"
fi
if [ -f "${SCRIPT_DIR}/logger.sh" ]; then
    source "${SCRIPT_DIR}/logger.sh"
fi

# Define standardized quality levels
declare -A QUALITY_LEVELS=(
    ["ultra"]=4    # Premium quality level
    ["high"]=3     # High quality, minimal compression
    ["medium"]=2   # Balanced quality and compression (default)
    ["low"]=1      # Maximum compression, reduced quality
)

# Default quality level
DEFAULT_QUALITY="medium"

# Quality level descriptions for user display
declare -A QUALITY_DESCRIPTIONS=(
    ["ultra"]="Premium quality with optimized file size (requires license)"
    ["high"]="High quality with minimal compression"
    ["medium"]="Balanced quality and compression (recommended)"
    ["low"]="Maximum compression with reduced quality"
)

# PDF quality settings mappings (Ghostscript)
declare -A PDF_QUALITY_SETTINGS=(
    ["ultra"]="/prepress"
    ["high"]="/printer"
    ["medium"]="/ebook"
    ["low"]="/screen"
)

# Image quality settings mappings (0-100)
declare -A IMAGE_QUALITY_SETTINGS=(
    ["ultra"]="95"
    ["high"]="90"
    ["medium"]="75"
    ["low"]="50"
)

# DPI settings by quality level
declare -A DPI_SETTINGS=(
    ["ultra"]="300"
    ["high"]="300"
    ["medium"]="150"
    ["low"]="72"
)

# Validate quality level
validate_quality_level() {
    local quality="$1"
    
    # Check if quality is in our defined levels
    if [ -z "${QUALITY_LEVELS[$quality]}" ]; then
        log_error "Invalid quality level: $quality"
        return 1
    fi
    
    # Check if premium features are required but not licensed
    if [ "$quality" = "ultra" ]; then
        if type is_feature_licensed &>/dev/null; then
            if ! is_feature_licensed "ultra_compression"; then
                log_error "Ultra quality requires a valid license"
                return 1
            fi
        else
            log_warning "License verification not available, allowing ultra quality"
        fi
    fi
    
    return 0
}

# Get quality level value (numeric)
get_quality_value() {
    local quality="${1:-$DEFAULT_QUALITY}"
    
    # Validate and return the numeric value
    if validate_quality_level "$quality"; then
        echo "${QUALITY_LEVELS[$quality]}"
        return 0
    else
        # Return default value on error
        echo "${QUALITY_LEVELS[$DEFAULT_QUALITY]}"
        return 1
    fi
}

# Get quality level setting for specified type
get_quality_setting() {
    local quality="${1:-$DEFAULT_QUALITY}"
    local type="${2:-pdf}"
    
    # Validate quality level
    if ! validate_quality_level "$quality"; then
        quality="$DEFAULT_QUALITY"
    fi
    
    # Return setting based on type
    case "$type" in
        pdf)
            echo "${PDF_QUALITY_SETTINGS[$quality]}"
            ;;
        image)
            echo "${IMAGE_QUALITY_SETTINGS[$quality]}"
            ;;
        dpi)
            echo "${DPI_SETTINGS[$quality]}"
            ;;
        *)
            log_error "Unknown quality setting type: $type"
            return 1
            ;;
    esac
    
    return 0
}

# List all available quality levels with descriptions
list_quality_levels() {
    echo "Available quality levels:"
    for level in "${!QUALITY_LEVELS[@]}"; do
        echo "  - $level: ${QUALITY_DESCRIPTIONS[$level]}"
    done
}

# Get recommended quality level based on file size
get_recommended_quality() {
    local file_size="$1"  # Size in bytes
    
    if [ "$file_size" -gt 10485760 ]; then  # > 10MB
        echo "medium"
    elif [ "$file_size" -gt 1048576 ]; then  # > 1MB
        echo "high"
    else
        echo "ultra"
    fi
}
