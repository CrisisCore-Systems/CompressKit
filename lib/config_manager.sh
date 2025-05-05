#!/data/data/com.termux/files/usr/bin/bash

# Configuration Manager for CompressKit
# Centralizes all configuration path definitions and handling

# Base paths 
readonly CM_HOME_DIR="$HOME"
readonly CM_CONFIG_BASE="$HOME/.config/compresskit"
readonly CM_DATA_DIR="$HOME/.local/share/compresskit"

# Configuration directories
readonly CM_CONFIG_DIR="$CM_CONFIG_BASE"
readonly CM_LOG_DIR="$CM_DATA_DIR/logs"
readonly CM_BACKUP_DIR="$CM_DATA_DIR/backups"
readonly CM_TEMP_DIR="/tmp/compresskit"

# Configuration files
readonly CM_CONFIG_FILE="$CM_CONFIG_DIR/config.yaml"
readonly CM_LICENSE_FILE="$CM_CONFIG_DIR/license.key"
readonly CM_LOG_FILE="$CM_LOG_DIR/compresskit.log"

# Permissions
readonly CM_DIR_PERMS="0750"    # rwxr-x---
readonly CM_FILE_PERMS="0640"   # rw-r-----
readonly CM_PRIVATE_PERMS="0600" # rw-------

# Import secure utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/secure_utils.sh" ]; then
    source "${SCRIPT_DIR}/secure_utils.sh"
fi

# Initialize configuration system
init_config_manager() {
    # Create required directories with proper permissions
    create_directory "$CM_CONFIG_DIR" "$CM_DIR_PERMS" || return 1
    create_directory "$CM_LOG_DIR" "$CM_DIR_PERMS" || return 1 
    create_directory "$CM_BACKUP_DIR" "$CM_DIR_PERMS" || return 1
    create_directory "$CM_TEMP_DIR" "$CM_DIR_PERMS" || return 1
    
    # Ensure license file has proper permissions if it exists
    if [ -f "$CM_LICENSE_FILE" ]; then
        chmod "$CM_PRIVATE_PERMS" "$CM_LICENSE_FILE" || {
            echo "Warning: Failed to set permissions on license file" >&2
        }
    fi
    
    return 0
}

# Create directory with proper permissions
create_directory() {
    local dir="$1"
    local perms="${2:-$CM_DIR_PERMS}"
    
    # Validate path
    local safe_dir
    safe_dir=$(safe_path "$dir")
    if [ $? -ne 0 ] || [ -z "$safe_dir" ]; then
        echo "Error: Invalid directory path: $dir" >&2
        return 1
    fi
    
    # Create directory if it doesn't exist
    if [ ! -d "$safe_dir" ]; then
        mkdir -p "$safe_dir" || {
            echo "Error: Failed to create directory: $safe_dir" >&2
            return 1
        }
    fi
    
    # Set permissions
    chmod "$perms" "$safe_dir" || {
        echo "Warning: Failed to set permissions on directory: $safe_dir" >&2
        return 0  # Continue despite permission issues
    }
    
    return 0
}

# Get configuration path
get_config_path() {
    local path_key="$1"
    
    case "$path_key" in
        "CONFIG_DIR") echo "$CM_CONFIG_DIR" ;;
        "LOG_DIR") echo "$CM_LOG_DIR" ;;
        "BACKUP_DIR") echo "$CM_BACKUP_DIR" ;;
        "TEMP_DIR") echo "$CM_TEMP_DIR" ;;
        "CONFIG_FILE") echo "$CM_CONFIG_FILE" ;;
        "LICENSE_FILE") echo "$CM_LICENSE_FILE" ;;
        "LOG_FILE") echo "$CM_LOG_FILE" ;;
        *)
            echo "Error: Unknown configuration path key: $path_key" >&2
            return 1
            ;;
    esac
    
    return 0
}

# Check if configuration manager is running in the main script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Configuration Manager - DirectPath Utility"
    echo "----------------------------------------"
    echo "Usage: $(basename "$0") <path_key>"
    echo ""
    echo "Available path keys:"
    echo "  CONFIG_DIR  - Configuration directory"
    echo "  LOG_DIR     - Log directory"
    echo "  BACKUP_DIR  - Backup directory" 
    echo "  TEMP_DIR    - Temporary directory"
    echo "  CONFIG_FILE - Configuration file"
    echo "  LICENSE_FILE - License file"
    echo "  LOG_FILE    - Log file"
    
    # Return path if argument provided
    if [[ -n "$1" ]]; then
        get_config_path "$1"
        exit $?
    fi
    
    exit 0
fi
