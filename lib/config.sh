#!/data/data/com.termux/files/usr/bin/bash

# Configuration management for CompressKit
# Handles all user preferences and system settings

# Default configuration paths
CONFIG_DIR="${HOME}/.config/compresskit"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
PRESETS_DIR="${CONFIG_DIR}/presets"

# Default settings
declare -A DEFAULT_CONFIG=(
    ["quality"]="medium"
    ["output_dir"]="${HOME}/Documents/compressed"
    ["compression_level"]="balanced"
    ["backup_enabled"]="true"
    ["log_level"]="INFO"
    ["theme"]="cyber"
    ["language"]="en"
)

# Quality presets
declare -A QUALITY_PRESETS=(
    ["ultra"]="gs -dPDFSETTINGS=/prepress -dColorImageResolution=300"
    ["high"]="gs -dPDFSETTINGS=/printer -dColorImageResolution=200"
    ["balanced"]="gs -dPDFSETTINGS=/ebook -dColorImageResolution=150"
    ["low"]="gs -dPDFSETTINGS=/screen -dColorImageResolution=72"
)

# Initialize configuration
init_config() {
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR" "$PRESETS_DIR"
    
    # Create default config if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        log_info "Creating default configuration..."
        create_default_config
    fi
    
    # Load configuration
    load_config
}

# Create default configuration file
create_default_config() {
    cat > "$CONFIG_FILE" << EOF
# CompressKit Configuration File
# Generated: $(date)

# General Settings
quality: ${DEFAULT_CONFIG["quality"]}
output_dir: ${DEFAULT_CONFIG["output_dir"]}
compression_level: ${DEFAULT_CONFIG["compression_level"]}
backup_enabled: ${DEFAULT_CONFIG["backup_enabled"]}
log_level: ${DEFAULT_CONFIG["log_level"]}
theme: ${DEFAULT_CONFIG["theme"]}
language: ${DEFAULT_CONFIG["language"]}

# Advanced Settings
threads: auto
temp_dir: /tmp/compresskit
preserve_metadata: true
EOF

    # Create output directory
    mkdir -p "${DEFAULT_CONFIG["output_dir"]}"
}

# Load configuration from file
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        while IFS=': ' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^#.*$ ]] || [ -z "$key" ] && continue
            CONFIG["$key"]="$value"
        done < "$CONFIG_FILE"
        log_debug "Configuration loaded successfully"
    else
        log_error "Configuration file not found"
        return 1
    fi
}

# Get configuration value
get_config() {
    local key="$1"
    local default="$2"
    
    if [ -n "${CONFIG[$key]}" ]; then
        echo "${CONFIG[$key]}"
    else
        echo "${default:-${DEFAULT_CONFIG[$key]}}"
    fi
}

# Set configuration value
set_config() {
    local key="$1"
    local value="$2"
    
    # Update memory configuration
    CONFIG["$key"]="$value"
    
    # Update configuration file
    if [ -f "$CONFIG_FILE" ]; then
        sed -i "s|^$key:.*|$key: $value|" "$CONFIG_FILE"
        log_debug "Updated configuration: $key = $value"
    else
        log_error "Configuration file not found"
        return 1
    fi
}

# Load compression preset
load_preset() {
    local preset_name="$1"
    local preset_file="${PRESETS_DIR}/${preset_name}.preset"
    
    if [ -f "$preset_file" ]; then
        source "$preset_file"
        log_debug "Loaded preset: $preset_name"
        return 0
    else
        log_error "Preset not found: $preset_name"
        return 1
    fi
}

# Save current settings as preset
save_preset() {
    local preset_name="$1"
    local preset_file="${PRESETS_DIR}/${preset_name}.preset"
    
    # Create preset file
    cat > "$preset_file" << EOF
# CompressKit Preset: $preset_name
# Created: $(date)

quality="${CONFIG["quality"]}"
compression_level="${CONFIG["compression_level"]}"
EOF
    
    log_info "Saved preset: $preset_name"
}

# Validate configuration
validate_config() {
    local valid=true
    
    # Check required directories
    for dir in "$CONFIG_DIR" "$PRESETS_DIR" "${CONFIG["output_dir"]}"; do
        if [ ! -d "$dir" ]; then
            log_error "Directory not found: $dir"
            valid=false
        fi
    done
    
    # Check quality setting
    if [[ ! "${CONFIG["quality"]}" =~ ^(ultra|high|balanced|low)$ ]]; then
        log_error "Invalid quality setting: ${CONFIG["quality"]}"
        valid=false
    fi
    
    # Check log level
    if [[ ! "${CONFIG["log_level"]}" =~ ^(DEBUG|INFO|WARN|ERROR|FATAL)$ ]]; then
        log_error "Invalid log level: ${CONFIG["log_level"]}"
        valid=false
    fi
    
    $valid
}
