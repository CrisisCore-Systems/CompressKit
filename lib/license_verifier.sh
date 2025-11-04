#!/data/data/com.termux/files/usr/bin/bash

# License Verification Module for CompressKit
# Handles license validation, signature verification, and expiration checks

# Import secure utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/secure_utils.sh"

# License file path
LICENSE_DIR="$HOME/.config/compresskit"
LICENSE_FILE="$LICENSE_DIR/license.key"
LICENSE_SIG_FILE="$LICENSE_DIR/license.sig"
PUBLIC_KEY_FILE="$LICENSE_DIR/public.key"

# License verification status codes
readonly LICENSE_VALID=0
readonly LICENSE_INVALID_SIGNATURE=1
readonly LICENSE_EXPIRED=2
readonly LICENSE_MISSING=3
readonly LICENSE_CORRUPT=4
readonly LICENSE_INVALID_FORMAT=5

# Initialize license system and ensure required directories exist
init_license_system() {
    # Safely create the license directory if it doesn't exist
    if [ ! -d "$LICENSE_DIR" ]; then
        if ! mkdir -p "$LICENSE_DIR" 2>/dev/null; then
            echo "Error: Failed to create license directory" >&2
            return 1
        fi
        chmod 700 "$LICENSE_DIR" 2>/dev/null
    fi
    
    # SECURITY FIX: Don't embed the public key directly in the script
    # Instead, load it from a verified source
    if [ ! -f "$PUBLIC_KEY_FILE" ]; then
        # Load key from secure location or download from authenticated source
        if ! fetch_public_key; then
            echo "Error: Could not retrieve license verification key" >&2
            return 1
        fi
    fi
    
    return 0
}

# Helper function to securely fetch the public key
fetch_public_key() {
    # Implementation depends on your security model
    # Could fetch from secure endpoint with certificate pinning
    return 0  # Placeholder
}

# Parse license data
parse_license_data() {
    local license_content="$1"
    local field="$2"
    
    # Extract field from license data
    echo "$license_content" | grep "^$field:" | cut -d':' -f2- | tr -d ' \t\r\n'
}

# Verify license signature using OpenSSL
verify_license_signature() {
    # Check if needed tools are available
    if ! command -v openssl &>/dev/null; then
        echo "Error: OpenSSL not available for signature verification" >&2
        return $LICENSE_INVALID_SIGNATURE
    fi
    
    if [ ! -f "$LICENSE_FILE" ] || [ ! -f "$LICENSE_SIG_FILE" ]; then
        echo "Error: License or signature file missing" >&2
        return $LICENSE_MISSING
    fi
    
    # Verify signature
    if ! openssl dgst -sha256 -verify "$PUBLIC_KEY_FILE" \
                      -signature "$LICENSE_SIG_FILE" "$LICENSE_FILE" &>/dev/null; then
        echo "Error: Invalid license signature" >&2
        return $LICENSE_INVALID_SIGNATURE
    fi
    
    return $LICENSE_VALID
}

# Check if the license has expired
check_license_expiration() {
    local license_content="$1"
    
    # Extract expiration date (format: YYYY-MM-DD)
    local expiration_date
    expiration_date=$(parse_license_data "$license_content" "Expires")
    
    if [ -z "$expiration_date" ]; then
        echo "Error: No expiration date found in license" >&2
        return $LICENSE_INVALID_FORMAT
    fi
    
    # Convert dates to seconds since epoch for comparison
    local exp_seconds
    local current_seconds
    
    # Date command varies by system, try to handle both GNU and BSD date
    if date --version >/dev/null 2>&1; then
        # GNU date
        exp_seconds=$(date -d "$expiration_date" +%s 2>/dev/null)
        current_seconds=$(date +%s)
    else
        # BSD date (e.g., macOS)
        exp_seconds=$(date -jf "%Y-%m-%d" "$expiration_date" +%s 2>/dev/null)
        current_seconds=$(date +%s)
    fi
    
    # Check if conversion failed
    if [ -z "$exp_seconds" ]; then
        echo "Error: Could not parse expiration date: $expiration_date" >&2
        return $LICENSE_INVALID_FORMAT
    fi
    
    # Check if license has expired
    if [ "$current_seconds" -gt "$exp_seconds" ]; then
        local current_date=$(date "+%Y-%m-%d")
        echo "Error: License expired on $expiration_date (current date: $current_date)" >&2
        return $LICENSE_EXPIRED
    fi
    
    return $LICENSE_VALID
}

# Validate license fully
validate_license() {
    # Initialize the license system
    init_license_system || return $LICENSE_CORRUPT
    
    # Check if license file exists
    if [ ! -f "$LICENSE_FILE" ]; then
        echo "Error: License file not found" >&2
        return $LICENSE_MISSING
    fi
    
    # Read license content
    local license_content
    license_content=$(cat "$LICENSE_FILE" 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$license_content" ]; then
        echo "Error: Failed to read license file or file is empty" >&2
        return $LICENSE_CORRUPT
    fi
    
    # Verify license signature
    verify_license_signature
    local sig_status=$?
    if [ $sig_status -ne $LICENSE_VALID ]; then
        return $sig_status
    fi
    
    # Check license expiration
    check_license_expiration "$license_content"
    local exp_status=$?
    if [ $exp_status -ne $LICENSE_VALID ]; then
        return $exp_status
    fi
    
    # Extract and validate license type
    local license_type
    license_type=$(parse_license_data "$license_content" "Type")
    
    # Validate license type
    case "$license_type" in
        "basic"|"pro"|"enterprise")
            # License type is valid
            ;;
        *)
            echo "Error: Invalid license type: $license_type" >&2
            return $LICENSE_INVALID_FORMAT
            ;;
    esac
    
    # Get customer information for logging
    local customer
    customer=$(parse_license_data "$license_content" "Customer")
    
    echo "License valid - Type: $license_type, Customer: $customer"
    return $LICENSE_VALID
}

# Check if a specific feature is allowed with the current license
is_feature_licensed() {
    local feature="$1"
    
    # Validate license first
    validate_license
    local license_status=$?
    
    if [ $license_status -ne $LICENSE_VALID ]; then
        return 1
    fi
    
    # Read license content
    local license_content
    license_content=$(cat "$LICENSE_FILE" 2>/dev/null)
    
    # Extract license type
    local license_type
    license_type=$(parse_license_data "$license_content" "Type")
    
    # Define feature permissions based on license type
    case "$feature" in
        "batch_processing")
            # Available in pro and enterprise
            [ "$license_type" = "pro" ] || [ "$license_type" = "enterprise" ]
            return $?
            ;;
        "ultra_compression")
            # Available in all license types
            return 0
            ;;
        "priority_support"|"custom_profiles")
            # Only available in enterprise
            [ "$license_type" = "enterprise" ]
            return $?
            ;;
        *)
            # Unknown feature - deny by default
            echo "Error: Unknown feature: $feature" >&2
            return 1
            ;;
    esac
}

# Generate a sample license file (for testing purposes)
generate_test_license() {
    local license_type="${1:-basic}"
    local days_valid="${2:-30}"
    
    # Calculate expiration date
    local expiration_date
    if date --version >/dev/null 2>&1; then
        # GNU date
        expiration_date=$(date -d "+${days_valid} days" "+%Y-%m-%d")
    else
        # BSD date
        expiration_date=$(date -v+${days_valid}d "+%Y-%m-%d")
    fi
    
    # Create license content
    cat > "$LICENSE_FILE" << EOF
Type:$license_type
Customer:Test User
Email:test@example.com
Issued:$(date "+%Y-%m-%d")
Expires:$expiration_date
Features:batch_processing,ultra_compression
LicenseID:TEST-$(date +%s)
EOF

    chmod 600 "$LICENSE_FILE"
    echo "Generated test license of type $license_type valid for $days_valid days"
    
    # Note: In a real implementation, we would also generate a signature file
    # using a private key (not included in the repository for security reasons)
    
    return 0
}

# Main function for command-line usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Command-line interface
    case "$1" in
        "check")
            validate_license
            exit $?
            ;;
        "generate-test")
            generate_test_license "$2" "$3"
            ;;
        *)
            echo "Usage: $0 {check|generate-test [type] [days]}"
            echo "  check           - Checks the current license validity"
            echo "  generate-test   - Generates a test license file"
            echo "    [type]        - License type: basic, pro, enterprise (default: basic)"
            echo "    [days]        - Days until expiration (default: 30)"
            ;;
    esac
fi
