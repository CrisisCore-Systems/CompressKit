#!/data/data/com.termux/files/usr/bin/bash

# Load Premium Features
PREMIUM_FEATURES=(
    "ultra_compression"
    "batch_processing"
    "priority_support"
    "custom_profiles"
)

# Import license verifier
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/license_verifier.sh"

# Check Premium License
check_premium_features() {
    # Validate the license
    validate_license >/dev/null
    return $?
}

# Generic Premium Feature Handler
feature_handler() {
    local feature_name="$1"
    local display_name="$2"
    
    # Check if feature is licensed
    if is_feature_licensed "$feature_name"; then
        echo "[✔] Access granted to $display_name"
        return 0
    fi
    
    echo -e "\033[31m[✘] $display_name requires a Premium License.\033[0m"
    echo "Visit: https://crisiscore-systems.com/premium"
    return 1
}

# Define Features
feature_ultra_compression() {
    feature_handler "ultra_compression" "Ultra Compression Algorithm"
}

feature_batch_processing() {
    feature_handler "batch_processing" "Batch Processing Support"
}

# Show Premium Features
show_premium_features() {
    echo -e "\033[34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\033[1m  Premium Features Available:\033[0m"
    for feature in "${PREMIUM_FEATURES[@]}"; do
        case $feature in
            "ultra_compression") 
                echo -n "  ∟ Ultra Compression Algorithm"
                if is_feature_licensed "ultra_compression"; then
                    echo -e " \033[32m[LICENSED]\033[0m"
                else
                    echo -e " \033[31m[UNLICENSED]\033[0m"
                fi
                ;;
            "batch_processing")  
                echo -n "  ∟ Batch Processing Support"
                if is_feature_licensed "batch_processing"; then
                    echo -e " \033[32m[LICENSED]\033[0m"
                else
                    echo -e " \033[31m[UNLICENSED]\033[0m"
                fi
                ;;
            "priority_support")  
                echo -n "  ∟ Priority Technical Support"
                if is_feature_licensed "priority_support"; then
                    echo -e " \033[32m[LICENSED]\033[0m"
                else
                    echo -e " \033[31m[UNLICENSED]\033[0m"
                fi
                ;;
            "custom_profiles")
                echo -n "  ∟ Custom Compression Profiles"
                if is_feature_licensed "custom_profiles"; then
                    echo -e " \033[32m[LICENSED]\033[0m"
                else
                    echo -e " \033[31m[UNLICENSED]\033[0m"
                fi
                ;;
        esac
    done
    
    # Display license status
    echo ""
    validate_license >/dev/null
    local license_status=$?
    
    case $license_status in
        0)
            echo -e "  \033[32mLicense Status: Valid\033[0m"
            ;;
        2)
            echo -e "  \033[31mLicense Status: Expired\033[0m"
            ;;
        *)
            echo -e "  \033[31mLicense Status: Invalid\033[0m"
            ;;
    esac
    
    echo ""
    echo "  Upgrade now at: crisiscore-systems.com/premium"
    echo -e "\033[34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
}
