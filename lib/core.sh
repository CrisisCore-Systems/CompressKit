#!/data/data/com.termux/files/usr/bin/bash

# Core functionality integration layer for CompressKit
# Coordinates between UI, logging, configuration, and compression modules

# Load all required modules
source "./lib/ui.sh"
source "./lib/logger.sh"
source "./lib/config.sh"
source "./lib/compress.sh"

# Initialize the system
init_system() {
    log_debug "Initializing CompressKit..."
    
    # Show startup animation
    matrix_rain 1
    
    # Initialize configuration
    init_config
    
    # Validate system requirements
    check_requirements
    
    # Initialize UI
    init_ui
    
    log_info "System initialized successfully"
}

# Check system requirements
check_requirements() {
    local requirements=(
        "gs:Ghostscript is required for PDF compression"
        "pdfinfo:PDFInfo is required for PDF analysis"
    )
    
    local all_met=true
    
    for req in "${requirements[@]}"; do
        local cmd="${req%%:*}"
        local msg="${req#*:}"
        
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "$msg"
            all_met=false
        fi
    done
    
    $all_met || exit 1
}

# Main workflow handler
handle_workflow() {
    local command="$1"
    shift
    
    case "$command" in
        "compress")
            handle_compression "$@"
            ;;
        "info")
            handle_pdf_info "$@"
            ;;
        "config")
            handle_configuration "$@"
            ;;
        *)
            show_help
            ;;
    esac
}

# Compression workflow
handle_compression() {
    local input_file="$1"
    local quality=$(get_config "quality")
    local output_dir=$(get_config "output_dir")
    
    # Validate input
    if [ ! -f "$input_file" ]; then
        log_error "Input file not found: $input_file"
        return 1
    fi
    
    # Show progress
    ui_info "Starting compression workflow..."
    compress_pdf "$input_file" "$quality" "$output_dir" &
    spinner $! "Compressing PDF..."
    
    # Verify results
    if [ $? -eq 0 ]; then
        ui_success "Compression completed successfully"
    else
        ui_error "Compression failed"
    fi
}

# Main entry point
main() {
    init_system
    handle_workflow "$@"
}
