#!/data/data/com.termux/files/usr/bin/bash

# Security incident handling module for CompressKit

# Import dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../secure_utils.sh"
source "${SCRIPT_DIR}/../logger.sh"

# Incident severity levels
declare -A SEVERITY_LEVELS=(
    ["LOW"]=1
    ["MEDIUM"]=2
    ["HIGH"]=3
    ["CRITICAL"]=4
)

# Initialize incident handler
init_incident_handler() {
    # Create incident directory if it doesn't exist
    local incident_dir="${HOME}/.compresskit/security/incidents"
    
    local safe_dir
    safe_dir=$(safe_path "$incident_dir")
    
    if [ $? -ne 0 ] || [ -z "$safe_dir" ]; then
        log_error "Invalid incident directory path"
        return 1
    fi
    
    if ! mkdir -p "$safe_dir" 2>/dev/null; then
        log_error "Failed to create incident directory at $safe_dir"
        return 1
    fi
    
    # Set secure permissions
    chmod 700 "$safe_dir" 2>/dev/null
    
    return 0
}

# Record security incident with severity classification
record_security_incident() {
    local incident_type="$1"
    local severity="${2:-MEDIUM}"
    local exit_code="${3:-1}"
    local details="${4:-No additional details}"
    
    # Validate severity
    if [ -z "${SEVERITY_LEVELS[$severity]}" ]; then
        severity="MEDIUM"  # Default to medium if invalid
    fi
    
    # Generate incident report file
    local timestamp=$(date '+%Y%m%d%H%M%S')
    local incident_dir="${HOME}/.compresskit/security/incidents"
    local report_file="${incident_dir}/incident_${severity}_${timestamp}.log"
    
    # Validate path
    local safe_report_file
    safe_report_file=$(safe_path "$report_file")
    
    if [ $? -ne 0 ] || [ -z "$safe_report_file" ]; then
        log_error "Invalid incident report path"
        return 1
    fi
    
    # Initialize handler if needed
    if [ ! -d "$incident_dir" ]; then
        init_incident_handler || return 1
    fi
    
    # Create detailed report
    {
        echo "====== SECURITY INCIDENT REPORT ======"
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "Incident Type: $incident_type"
        echo "Severity: $severity (${SEVERITY_LEVELS[$severity]})"
        echo "Exit Code: $exit_code"
        echo "Username: $(id -un 2>/dev/null || echo 'unknown')"
        echo "Hostname: $(hostname 2>/dev/null || echo 'unknown')"
        echo "Working Directory: $PWD"
        echo "Command: $0 $*"
        echo "Stack Trace:"
        if declare -p ERROR_STACK &>/dev/null; then
            for error in "${ERROR_STACK[@]}"; do
                echo "  $error"
            done
        else
            echo "  Stack trace unavailable"
        fi
        echo "Additional Details:"
        echo "$details"
        echo "====================================="
    } > "$safe_report_file"
    
    # Set secure permissions
    chmod 600 "$safe_report_file"
    
    log_warning "Security incident report created: $safe_report_file"
    
    # Notify admin if configured (using existing function)
    if type notify_admin &>/dev/null; then
        notify_admin "SECURITY_INCIDENT" "$safe_report_file" "$severity"
    fi
    
    # For critical incidents, take immediate action
    if [ "$severity" = "CRITICAL" ]; then
        log_error "CRITICAL SECURITY INCIDENT DETECTED - Additional protective measures engaged"
        # Add critical incident response here
    fi
    
    return 0
}

# Generate security incident metrics report
generate_incident_metrics() {
    local incident_dir="${HOME}/.compresskit/security/incidents"
    local safe_dir
    safe_dir=$(safe_path "$incident_dir")
    
    if [ $? -ne 0 ] || [ -z "$safe_dir" ] || [ ! -d "$safe_dir" ]; then
        log_error "Invalid or non-existent incident directory"
        return 1
    fi
    
    # Count incidents by severity
    local critical_count=0
    local high_count=0
    local medium_count=0
    local low_count=0
    
    # Count files by pattern (safely)
    if [ -d "$safe_dir" ]; then
        critical_count=$(find "$safe_dir" -name "incident_CRITICAL_*.log" 2>/dev/null | wc -l)
        high_count=$(find "$safe_dir" -name "incident_HIGH_*.log" 2>/dev/null | wc -l)
        medium_count=$(find "$safe_dir" -name "incident_MEDIUM_*.log" 2>/dev/null | wc -l)
        low_count=$(find "$safe_dir" -name "incident_LOW_*.log" 2>/dev/null | wc -l)
    fi
    
    # Output metrics
    echo "Security Incident Metrics"
    echo "========================="
    echo "Critical incidents: $critical_count"
    echo "High severity incidents: $high_count"
    echo "Medium severity incidents: $medium_count"
    echo "Low severity incidents: $low_count"
    echo "Total incidents: $((critical_count + high_count + medium_count + low_count))"
    
    return 0
}
