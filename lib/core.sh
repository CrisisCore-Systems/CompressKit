#!/data/data/com.termux/files/usr/bin/bash

# Core functionality integration layer for CompressKit
# Coordinates between UI, logging, configuration, and compression modules

# The roots of CompressKit—where every node in the system grows.

# Load all required modules (the branches of the tree)
for module in "./lib/ui.sh" "./lib/logger.sh" "./lib/config.sh" "./lib/compress.sh"; do
    if [ -f "$module" ]; then
        source "$module"
    else
        echo "Missing essential module: $module"
        exit 1
    fi
done

# The "roots" of CompressKit—initializing the sacred system.
init_system() {
    log_debug "Breathing life into CompressKit..."
    
    # Show startup animation (the awakening)
    matrix_rain 1
    
    # Initialize configuration (the soil of our tree)
    init_config
    
    # Validate system requirements (the Gatekeeper checks the path forward)
    check_requirements
    
    # Initialize UI (the canopy where users interact)
    init_ui
    
    log_info "System initialized successfully"
}

# Invoke the mythical guardian to check system requirements
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
            log_error "$msg (The Gatekeeper denies entry: '$cmd')"
            all_met=false
        fi
    done
    
    # Enhanced dependency checking with versions
    local dependencies=(
        "gs:4.0:Ghostscript is required for PDF compression"
        "openssl:1.1.0:OpenSSL is required for license verification"
        "bash:4.0:Bash 4.0+ is required"
    )
    
    for dep in "${dependencies[@]}"; do
        IFS=':' read -r cmd min_ver msg <<< "$dep"
        
        # Check if command exists
        if ! command -v "$cmd" &>/dev/null; then
            log_error "$msg (command not found: '$cmd')"
            all_met=false
            continue
        fi
        
        # Check version if specified
        if [ -n "$min_ver" ]; then
            local ver
            case "$cmd" in
                gs)
                    ver=$(gs --version 2>/dev/null | head -n 1)
                    ;;
                openssl)
                    ver=$(openssl version | cut -d' ' -f2)
                    ;;
                bash)
                    ver=${BASH_VERSION%.*}
                    ;;
            esac
            
            # Simple version comparison
            if ! meets_minimum_version "$ver" "$min_ver"; then
                log_error "$msg (found version $ver, need $min_ver+)"
                all_met=false
            fi
        fi
    done
    
    $all_met || exit 1
}

# Helper function to check version requirements
meets_minimum_version() {
    local current="$1"
    local required="$2"
    
    # Convert versions to comparable integers
    local current_parts=( ${current//./ } )
    local required_parts=( ${required//./ } )
    
    # Compare major version
    if [[ ${current_parts[0]} -lt ${required_parts[0]} ]]; then
        return 1
    elif [[ ${current_parts[0]} -gt ${required_parts[0]} ]]; then
        return 0
    fi
    
    # Compare minor version if major is equal
    if [[ ${#current_parts[@]} -gt 1 && ${#required_parts[@]} -gt 1 ]]; then
        if [[ ${current_parts[1]} -lt ${required_parts[1]} ]]; then
            return 1
        fi
    fi
    
    return 0
}

# Recursive workflow handler—each branch leads deeper into the tree
handle_workflow() {
    local command="$1"
    shift
    
    # Base case
    if [ -z "$command" ]; then
        show_help
        return
    fi

    # Recursive call
    case "$command" in
        "compress"|"info"|"config")
            handle_$command "$@"
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            ;;
    esac
}

# ⚙️ The forge of CompressKit - where PDFs are reforged into lighter artifacts
handle_compression() {
    local input_file="$1"
    local quality=$(get_config "quality")
    local output_dir=$(get_config "output_dir")
    
    # Validate input (checking the artifact's integrity)
    if [ ! -f "$input_file" ]; then
        log_error "The artifact was not found: $input_file"
        return 1
    fi
    
    # Show progress (the blacksmith begins their work)
    ui_info "Starting compression workflow..."
    compress_pdf "$input_file" "$quality" "$output_dir" &
    spinner $! "Invoking the compression daemon..."
    
    # Verify results (the artifact's rebirth)
    if [ $? -eq 0 ]; then
        ui_success "Compression completed successfully"
    else
        ui_error "Compression failed"
    fi
}

# Main entry point (the trunk of the tree—where all branches converge)
main() {
    init_system
    handle_workflow "$@"
}
