#!/bin/bash

# Engraving the configuration scrolls of CompressKit—a recursive architect's toolkit.

CONFIG_FILE="$HOME/.config/compresskit/config.yaml"
LICENSE_FILE="$HOME/.config/compresskit/license.key"

# Logs narrative messages to the console
log() {
    echo "[CompressKit Myth] $1"
}

# Sets a key-value pair in the configuration scroll
set_config() {
    local key="$1"
    local value="$2"

    log "Engraving $key into the configuration scroll..."
    mkdir -p "$(dirname "$CONFIG_FILE")" || {
        log "Error: Could not create directory for config file."
        return 1
    }

    if [ -f "$CONFIG_FILE" ]; then
        sed -i "/^${key}:/d" "$CONFIG_FILE" || {
            log "Error: Failed to update $CONFIG_FILE."
            return 1
        }
    fi

    echo "$key: $value" >> "$CONFIG_FILE" || {
        log "Error: Failed to write to $CONFIG_FILE."
        return 1
    }
}

# Retrieves a value for a given key from the configuration scroll
get_config() {
    local key="$1"
    local value
    value=$(grep "^${key}:" "$CONFIG_FILE" 2>/dev/null | cut -d ':' -f2- | tr -d ' \t\r\n') || {
        log "Error: Could not read $key from $CONFIG_FILE."
        return 1
    }
    echo "$value"
}

# Validates the YAML structure of the configuration scroll
validate_config() {
    log "Validating the sacred structure of the configuration scroll..."
    if ! command -v yq &>/dev/null; then
        log "Warning: YAML validation skipped as 'yq' is not installed."
        return 0
    fi

    yq eval '.' "$CONFIG_FILE" &>/dev/null || {
        log "Error: The configuration scroll contains invalid YAML."
        return 1
    }
}

# Checks the existence of the premium license key
check_premium_features() {
    log "Verifying the existence of the sacred premium license key..."
    if [ -f "$LICENSE_FILE" ]; then
        chmod 600 "$LICENSE_FILE" || {
            log "Error: Failed to secure the license key."
            return 1
        }
        return 0
    fi
    log "No sacred license key found. Premium features are locked."
    return 1
}
