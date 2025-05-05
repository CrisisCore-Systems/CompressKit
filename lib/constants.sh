#!/data/data/com.termux/files/usr/bin/bash

# Constants module for CompressKit
# Provides centralized configuration constants to eliminate hardcoded values

# Software version
readonly CK_VERSION="1.0.1"
readonly CK_BUILD_NUMBER="1001"
readonly CK_RELEASE_DATE="2024-01-15"

# File system paths
readonly CK_HOME_DIR="$HOME/.compresskit"
readonly CK_CONFIG_DIR="$HOME/.config/compresskit"
readonly CK_LOG_DIR="${CK_HOME_DIR}/logs"
readonly CK_BACKUP_DIR="${CK_HOME_DIR}/backups"
readonly CK_TEMP_DIR="/tmp/compresskit"

# Configuration files
readonly CK_CONFIG_FILE="${CK_CONFIG_DIR}/config.yaml"
readonly CK_LICENSE_FILE="${CK_CONFIG_DIR}/license.key"
readonly CK_LOG_FILE="${CK_LOG_DIR}/compresskit.log"

# Default file permissions (numeric)
readonly CK_PERM_CONFIG_DIR="0700"
readonly CK_PERM_CONFIG_FILE="0600"
readonly CK_PERM_LOG_DIR="0750"
readonly CK_PERM_LOG_FILE="0640"
readonly CK_PERM_PUBLIC_DIR="0755"
readonly CK_PERM_PUBLIC_FILE="0644"
readonly CK_PERM_BACKUP_FILE="0600"
readonly CK_PERM_TEMP_FILE="0600"

# Maximum file sizes
readonly CK_MAX_CONFIG_SIZE_KB=128
readonly CK_MAX_LOG_SIZE_KB=1024
readonly CK_MAX_UPLOAD_SIZE_MB=100

# Timeouts (in seconds)
readonly CK_CONNECTION_TIMEOUT=30
readonly CK_PROCESS_TIMEOUT=300
readonly CK_UI_TIMEOUT=300

# API endpoints and contact information
readonly CK_SUPPORT_EMAIL="support@crisiscore-systems.com"
readonly CK_ADMIN_EMAIL="admin@crisiscore-systems.com"
readonly CK_WEBSITE="https://crisiscore-systems.com"
readonly CK_API_BASE_URL="https://api.crisiscore-systems.com/v1"

# Compression quality presets
readonly CK_QUALITY_SETTINGS=(
    ["high"]="-dPDFSETTINGS=/prepress -dColorImageResolution=300"
    ["medium"]="-dPDFSETTINGS=/ebook -dColorImageResolution=150"
    ["low"]="-dPDFSETTINGS=/screen -dColorImageResolution=72"
)

# File type patterns
readonly CK_PDF_PATTERN="*.pdf"
readonly CK_IMAGE_PATTERN="*.{jpg,jpeg,png,gif}"
readonly CK_DOCUMENT_PATTERN="*.{doc,docx,txt,rtf}"

# Exit status codes
readonly CK_SUCCESS=0
readonly CK_ERROR_GENERAL=1
readonly CK_ERROR_INVALID_ARGS=2
readonly CK_ERROR_FILE_NOT_FOUND=3
readonly CK_ERROR_PERMISSION_DENIED=4
readonly CK_ERROR_DEPENDENCY_MISSING=5
readonly CK_ERROR_CONFIG_INVALID=6
readonly CK_ERROR_COMPRESSION_FAILED=7
readonly CK_ERROR_LICENSE_INVALID=8
readonly CK_ERROR_NETWORK=9
readonly CK_ERROR_TIMEOUT=10
readonly CK_ERROR_UNKNOWN=99

# Return the path to a directory, ensuring it exists with proper permissions
# Usage: ensure_directory "dir_path" "permissions"
ensure_directory() {
    local dir="$1"
    local perms="${2:-0755}"
    
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || return 1
    fi
    
    chmod "$perms" "$dir" || return 1
    return 0
}

# Return the path to a configuration value or default if not found
# Usage: get_config_value "key" "default_value"
get_config_value() {
    local key="$1"
    local default="$2"
    
    if [ -f "$CK_CONFIG_FILE" ] && command -v grep &>/dev/null; then
        local value
        value=$(grep "^${key}:" "$CK_CONFIG_FILE" 2>/dev/null | cut -d ':' -f2- | tr -d ' \t\r\n')
        if [ -n "$value" ]; then
            echo "$value"
            return 0
        fi
    fi
    
    echo "$default"
    return 0
}
