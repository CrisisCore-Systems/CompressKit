#!/data/data/com.termux/files/usr/bin/bash

# Import secure utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/secure_utils.sh" ]; then
    source "${SCRIPT_DIR}/secure_utils.sh"
fi

# Engraving the configuration scrolls of CompressKit—a recursive architect's toolkit.

# SECURITY FIX: Define safer default paths with permissions
CONFIG_DIR="$HOME/.config/compresskit"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
LICENSE_FILE="$CONFIG_DIR/license.key"
DEFAULT_CONFIG_PERMS="0600"  # Restrictive file permissions
DEFAULT_DIR_PERMS="0700"     # Restrictive directory permissions

# Logs narrative messages to the console
log() {
    echo "[CompressKit Myth] $1"
}

# SECURITY FIX: Safely create configuration directory with proper permissions
init_config_dir() {
    # Create config directory if it doesn't exist
    if [ ! -d "$CONFIG_DIR" ]; then
        if ! mkdir -p "$CONFIG_DIR"; then
            log "Error: Could not create configuration directory."
            return 1
        fi
        # Set secure permissions
        chmod "$DEFAULT_DIR_PERMS" "$CONFIG_DIR" || {
            log "Error: Could not set permissions on configuration directory."
            return 1
        }
    fi
    return 0
}

# Create default configuration with secure permissions
create_default_config() {
    init_config_dir || return 1
    
    # SECURITY FIX: Use a secure temporary file approach for atomic writes
    local temp_config
    temp_config=$(secure_tempfile "config")
    
    if [ $? -ne 0 ]; then
        log "Error: Could not create temporary file."
        return 1
    fi
    
    # Create default configuration
    cat > "$temp_config" << EOF
# CompressKit Configuration
# Generated: $(date)

# Compression settings
quality: medium
backup_files: true
keep_metadata: false

# System settings
output_dir: $HOME/Documents/compressed
temp_dir: /tmp/compresskit
backup_dir: $HOME/.compresskit/backups
log_file: $HOME/.compresskit/logs/compresskit.log
admin_email: admin@example.com
EOF
    
    # Set secure permissions before moving to final location
    chmod "$DEFAULT_CONFIG_PERMS" "$temp_config" || {
        log "Error: Failed to set permissions on temporary config file."
        rm -f "$temp_config"
        return 1
    }
    
    # Move to final location (atomic operation)
    mv "$temp_config" "$CONFIG_FILE" || {
        log "Error: Failed to create config file."
        rm -f "$temp_config"
        return 1
    }
    
    log "Default configuration created with secure permissions."
    return 0
}

# Sets a key-value pair in the configuration scroll
set_config() {
    local key="$1"
    local value="$2"
    
    # SECURITY FIX: Validate key and value
    if [[ ! "$key" =~ ^[a-zA-Z0-9_]+$ ]]; then
        log "Error: Invalid configuration key format."
        return 1
    fi
    
    # Ensure configuration directory exists with proper permissions
    init_config_dir || return 1

    # SECURITY FIX: Use temporary file for atomic updates
    local temp_config
    temp_config=$(secure_tempfile "config")
    
    if [ $? -ne 0 ]; then
        log "Error: Could not create temporary file."
        return 1
    fi
    
    if [ -f "$CONFIG_FILE" ]; then
        # Copy existing config excluding the key to be updated
        grep -v "^${key}:" "$CONFIG_FILE" > "$temp_config" || {
            log "Error: Failed to process existing configuration."
            rm -f "$temp_config"
            return 1
        }
    fi
    
    # Add the new key-value pair
    echo "$key: $value" >> "$temp_config" || {
        log "Error: Failed to write to temporary config file."
        rm -f "$temp_config"
        return 1
    }
    
    # Set secure permissions
    chmod "$DEFAULT_CONFIG_PERMS" "$temp_config" || {
        log "Error: Failed to set permissions on temporary config file."
        rm -f "$temp_config"
        return 1
    }
    
    # Move to final location (atomic operation)
    mv "$temp_config" "$CONFIG_FILE" || {
        log "Error: Failed to update config file."
        rm -f "$temp_config"
        return 1
    }
    
    return 0
}

# Retrieves a value for a given key from the configuration scroll
get_config() {
    local key="$1"
    local default_value="$2"
    
    # SECURITY FIX: Validate key format
    if [[ ! "$key" =~ ^[a-zA-Z0-9_]+$ ]]; then
        log "Error: Invalid configuration key format."
        echo "$default_value"
        return 1
    fi
    
    # If config file doesn't exist, create default or return default value
    if [ ! -f "$CONFIG_FILE" ]; then
        if [ -n "$default_value" ]; then
            echo "$default_value"
            return 0
        else
            create_default_config
        fi
    fi
    
    # Read value safely
    local value
    value=$(grep "^${key}:" "$CONFIG_FILE" 2>/dev/null | cut -d ':' -f2- | tr -d ' \t\r\n')
    
    # Return default if key not found or empty
    if [ -z "$value" ] && [ -n "$default_value" ]; then
        echo "$default_value"
    else
        echo "$value"
    fi
    
    return 0
}

# Validates the YAML structure of the configuration scroll
validate_config() {
    log "Validating the sacred structure of the configuration scroll..."
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        log "Configuration file does not exist. Creating default configuration..."
        create_default_config
        return $?
    fi
    
    # Check file permissions
    local perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || stat -f "%Lp" "$CONFIG_FILE" 2>/dev/null)
    if [ "$perms" != "600" ]; then
        log "Warning: Insecure permissions on config file. Fixing..."
        chmod 600 "$CONFIG_FILE"
    fi
    
    if ! command -v yq &>/dev/null; then
        log "Warning: YAML validation skipped as 'yq' is not installed."
        return 0
    fi

    yq eval '.' "$CONFIG_FILE" &>/dev/null || {
        log "Error: The configuration file contains invalid YAML."
        log "Creating backup and generating new default configuration."
        
        # Backup invalid config
        local backup="${CONFIG_FILE}.$(date +%Y%m%d%H%M%S).bak"
        cp "$CONFIG_FILE" "$backup" && chmod 600 "$backup"
        
        # Create new config
        create_default_config
        return $?
    }
    
    log "Configuration validated successfully."
    return 0
}

# Checks the existence of the premium license key
check_premium_features() {
    log "Verifying the existence of the sacred premium license key..."
    
    # Create config directory if it doesn't exist
    init_config_dir || return 1
    
    if [ -f "$LICENSE_FILE" ]; then
        # SECURITY FIX: Always ensure license file has secure permissions
        chmod 600 "$LICENSE_FILE" || {
            log "Error: Failed to secure the license key."
            return 1
        }
        return 0
    fi
    
    log "No sacred license key found. Premium features are locked."
    return 1
}

# Initialize configuration system
init_config() {
    # Create default config if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        create_default_config
    else
        # Validate existing config
        validate_config
    fi
    
    # Ensure license file has secure permissions if it exists
    if [ -f "$LICENSE_FILE" ]; then
        chmod 600 "$LICENSE_FILE"
    fi
    
    return 0
}
