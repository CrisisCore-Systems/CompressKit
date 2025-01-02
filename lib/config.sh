#!/bin/bash

CONFIG_FILE="$HOME/.config/compresskit/config.yaml"
LICENSE_FILE="$HOME/.config/compresskit/license.key"

set_config() {
    local key="$1"
    local value="$2"

    mkdir -p "$(dirname "$CONFIG_FILE")"
    if [ -f "$CONFIG_FILE" ]; then
        sed -i "/^${key}:/d" "$CONFIG_FILE"
    fi
    echo "$key: $value" >> "$CONFIG_FILE"
}

get_config() {
    local key="$1"
    local value
    value=$(grep "^${key}:" "$CONFIG_FILE" 2>/dev/null | cut -d ':' -f2- | tr -d ' \t\r\n')
    echo "$value"
}

check_premium_features() {
    if [ -f "$LICENSE_FILE" ]; then
        return 0
    fi
    return 1
}
