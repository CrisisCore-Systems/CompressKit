#!/data/data/com.termux/files/usr/bin/bash

# UI Component Library for CompressKit
# Handles all visual elements and user interaction: Recursive systems of presentation.

# Import secure utilities if available
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${script_dir}/secure_utils.sh" ]; then
    source "${script_dir}/secure_utils.sh"
fi

# Source UI theme constants (modularized for adaptability)
ui_theme="${script_dir}/ui_theme.sh"
if [ -f "$ui_theme" ]; then
    source "$ui_theme"
else
    # Fallback UI colors and symbols if theme file is not available
    declare -A ui_colors=(
        ["primary"]="\033[1;36m"    # Cyan
        ["secondary"]="\033[1;35m"  # Magenta
        ["info"]="\033[1;34m"       # Blue
        ["success"]="\033[1;32m"    # Green
        ["warning"]="\033[1;33m"    # Yellow
        ["error"]="\033[1;31m"      # Red
        ["muted"]="\033[1;30m"      # Gray
        ["reset"]="\033[0m"         # Reset
    )
    
    declare -A ui_symbols=(
        ["success"]="✔"
        ["error"]="✘"
        ["warning"]="⚠"
        ["info"]="ℹ"
        ["arrow"]="▶"
        ["bullet"]="•"
    )
fi

# SECURITY FIX: Safe terminal size detection with defaults
get_terminal_size() {
    # Default values
    lines=24
    columns=80
    
    # Try to get actual terminal size
    if command -v tput &>/dev/null; then
        local detected_lines detected_columns
        detected_lines=$(tput lines 2>/dev/null) && lines=$detected_lines
        detected_columns=$(tput cols 2>/dev/null) && columns=$detected_columns
    elif command -v stty &>/dev/null; then
        local size
        size=$(stty size 2>/dev/null) && {
            lines=${size% *}
            columns=${size#* }
        }
    fi
    
    # Sanity check
    if [ "$lines" -lt 10 ]; then lines=24; fi
    if [ "$columns" -lt 40 ]; then columns=80; fi
    
    # Export variables
    export lines columns
}

# Initialize terminal size
get_terminal_size

# --- Matrix Rain: Echoing the collapse of data streams ---
matrix_rain() {
    # SECURITY FIX: Validate duration input
    local duration=${1:-10}
    if ! [[ "$duration" =~ ^[0-9]+$ ]] || [ "$duration" -lt 1 ] || [ "$duration" -gt 60 ]; then
        duration=10  # Default to 10 seconds if invalid input
    fi
    
    local charset=("@", "#", "$", "%", "&", "*", "+", "-")  # Customizable glyphs
    local density=$((columns / 10))  # Characters per row recalibrated for recursive density
    
    # SECURITY FIX: Ensure safe terminal state
    local end_time=$((SECONDS + duration))
    # Save current terminal state if commands available
    if command -v tput &>/dev/null; then
        tput sc; tput civis
    fi

    while [ $SECONDS -lt $end_time ]; do
        for ((i = 0; i < density; i++)); do
            local x=$((RANDOM % columns))
            local y=$((RANDOM % lines))
            # Ensure x and y are within bounds
            [ "$x" -lt "$columns" ] || continue
            [ "$y" -lt "$lines" ] || continue
            
            local char="${charset[RANDOM % ${#charset[@]}]}"
            # Use tput only if available
            if command -v tput &>/dev/null; then
                tput cup "$y" "$x"
                echo -en "${ui_colors[primary]}$char${ui_colors[reset]}"
            fi
        done
        sleep 0.05
    done

    # Restore terminal state if commands available
    if command -v tput &>/dev/null; then
        tput rc; tput cnorm
    fi
}

# --- Interactive Progress Bar: Time's arrow moving forward ---
progress_bar() {
    # SECURITY FIX: Validate numeric inputs
    local current=$1
    local total=$2
    local label=${3:-"Progress"}
    
    # Validate numeric inputs
    if ! [[ "$current" =~ ^[0-9]+$ ]] || ! [[ "$total" =~ ^[0-9]+$ ]]; then
        echo "Error: progress_bar requires numeric inputs" >&2
        return 1
    fi
    
    # Prevent division by zero
    if [ "$total" -eq 0 ]; then
        total=1
    fi
    
    # Limit progress to 100%
    if [ "$current" -gt "$total" ]; then
        current="$total"
    fi
    
    # Calculate progress bar width
    local width=$((columns - 20))  # Dynamic recalibration for terminal size
    if [ "$width" -lt 20 ]; then
        width=20  # Minimum width
    fi
    
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    # Sanitize label
    label="${label//[^a-zA-Z0-9 _-]/}"
    
    printf "\r${ui_colors[info]}%s:${ui_colors[reset]} [" "$label"
    printf "%${filled}s" | tr " " "█"
    printf "%${empty}s" | tr " " "░"
    printf "] %3d%%" "$percentage"
    
    return 0
}

# --- Spinner: Recursive cycles of waiting ---
spinner() {
    # SECURITY FIX: Validate process ID
    local pid=$1
    local message=${2:-"Loading"}
    local timeout=${3:-30}  # Recursive timer (fail-safe)
    
    # Validate PID
    if ! [[ "$pid" =~ ^[0-9]+$ ]] || ! kill -0 "$pid" 2>/dev/null; then
        echo "Error: Invalid or non-existent process ID" >&2
        return 1
    fi
    
    # Validate timeout
    if ! [[ "$timeout" =~ ^[0-9]+$ ]] || [ "$timeout" -lt 1 ] || [ "$timeout" -gt 300 ]; then
        timeout=30  # Default to 30 seconds if invalid
    fi
    
    # Sanitize message
    message="${message//[^a-zA-Z0-9 _-:.]/}"
    
    local spinner_set=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local end_time=$((SECONDS + timeout))
    local i=0

    while kill -0 $pid 2>/dev/null && [ $SECONDS -lt $end_time ]; do
        printf "\r${ui_colors[primary]}%s${ui_colors[reset]} %s" "${spinner_set[i]}" "$message"
        i=$(((i + 1) % ${#spinner_set[@]}))
        sleep 0.1
    done
    
    # Check if process is still running after timeout
    if kill -0 $pid 2>/dev/null; then
        printf "\r${ui_colors[warning]}Timeout!${ui_colors[reset]} %s\n" "$message"
    else
        printf "\r${ui_colors[success]}Done!${ui_colors[reset]}%*s\n" $((${#message} + 2)) " "
    fi
    
    return 0
}

# --- Status Messages: Echoing validation ---
ui_success() { echo -e "${ui_colors[success]}${ui_symbols[success]} ${1//[\`\$\"\\\n\r]/}${ui_colors[reset]}"; }
ui_error() { echo -e "${ui_colors[error]}${ui_symbols[error]} ${1//[\`\$\"\\\n\r]/}${ui_colors[reset]}"; }
ui_warning() { echo -e "${ui_colors[warning]}${ui_symbols[warning]} ${1//[\`\$\"\\\n\r]/}${ui_colors[reset]}"; }
ui_info() { echo -e "${ui_colors[info]}${ui_symbols[info]} ${1//[\`\$\"\\\n\r]/}${ui_colors[reset]}"; }

# --- Interactive Menu: Recursive branching of options ---
ui_menu() {
    local title=$1
    shift
    local options=("$@")
    
    # Validate inputs
    if [ ${#options[@]} -eq 0 ]; then
        ui_error "No menu options provided"
        return 1
    fi
    
    # Sanitize title
    title="${title//[\`\$\"\\\n\r]/}"
    
    local selected=0
    local key

    # Update terminal size
    get_terminal_size

    while true; do
        clear
        echo -e "${ui_colors[primary]}$title${ui_colors[reset]}\n"

        for i in "${!options[@]}"; do
            # Sanitize option text
            local option="${options[i]//[\`\$\"\\\n\r]/}"
            
            if [ $i -eq $selected ]; then
                echo -e "${ui_colors[primary]}${ui_symbols[arrow]} ${option}${ui_colors[reset]}"
            else
                echo -e "${ui_colors[muted]}  ${option}${ui_colors[reset]}"
            fi
        done

        # Read key with timeout
        read -rsn1 -t 300 key || {
            ui_warning "Menu timed out after 5 minutes of inactivity"
            return 255
        }
        
        case "$key" in
            $'\x1B')
                read -rsn2 -t 0.1 key || continue
                case "$key" in
                    '[A') ((selected--)) ;;  # Navigate up the recursive tree
                    '[B') ((selected++)) ;;  # Navigate down the recursive tree
                esac
                ;;
            '') break ;;  # Select current node
            'q'|'Q') return 255 ;;  # Allow quitting with 'q'
        esac

        selected=$((selected % ${#options[@]}))
        [ $selected -lt 0 ] && selected=$((${#options[@]} - 1))
    done

    return $selected
}

# --- Confirmation Dialog: Recursive yes/no decision-making ---
ui_confirm() {
    local message=$1
    local default=${2:-y}
    
    # Sanitize message
    message="${message//[\`\$\"\\\n\r]/}"
    
    # Validate default value
    if [[ ! "$default" =~ ^[YyNn]$ ]]; then
        default="y"
    fi

    while true; do
        printf "${ui_colors[primary]}${ui_symbols[bullet]} %s [y/n] ${ui_colors[reset]}" "$message"
        read -r -n 1 -t 300 response || {
            ui_warning "Confirmation dialog timed out"
            return 2
        }
        echo

        case "$response" in
            [yY]) return 0 ;;
            [nN]) return 1 ;;
            '') [ "$default" = "y" ] || [ "$default" = "Y" ] && return 0 || return 1 ;;
            *) ui_error "Please answer y or n" ;;
        esac
    done
}

# Initialize UI
init_ui() {
    # Update terminal size
    get_terminal_size
    
    # Clear the screen if not in test mode
    if [ "${test_mode:-0}" -eq 0 ] && command -v tput &>/dev/null; then
        tput clear
    fi
    
    return 0
}

# --- Example Usage ---
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    init_ui
    ui_menu "Choose an option:" "Option 1" "Option 2" "Quit"
    choice=$?
    echo "You selected option $choice"
fi
