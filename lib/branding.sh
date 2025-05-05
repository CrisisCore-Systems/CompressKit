#!/data/data/com.termux/files/usr/bin/bash

# Load configurations from branding.conf
source "$(dirname "$0")/branding.conf"

# Function to display the branding banner
show_banner() {
    local COLOR_RESET="\033[0m"
    local COLOR_BLUE="\033[1;34m"
    local COLOR_CYAN="\033[1;36m"

    echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_CYAN}  CrisisCore-Systems CompressKit Enterprise${COLOR_RESET}"
    echo -e "${COLOR_CYAN}  Version: ${CC_VERSION} (Build ${CC_BUILD})${COLOR_RESET}"
    echo -e "${COLOR_CYAN}  Licensed under CrisisCore-Systems Enterprise Agreement${COLOR_RESET}"
    echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "  \"Optimizing the weight of worlds, one PDF at a time.\""
}

# Function to validate the license using an external script
check_license() {
    local license_key="$1"
    "$(dirname "$0")/validate_license.sh" "$license_key" || {
        echo "Invalid license key. Exiting."
        exit 1
    }
}

# Log errors for auditing
log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$(dirname "$0")/compresskit.log"
}

# Trap unexpected errors and log them
trap 'log_error "An unexpected error occurred."' ERR

# Example usage
show_banner
# Uncomment the next line to check a license key
# check_license "YOUR_LICENSE_KEY"
