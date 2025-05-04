#!/data/data/com.termux/files/usr/bin/bash

# UI Component Library for CompressKit
# Handles all visual elements and user interaction: Recursive systems of presentation.

# Source UI theme constants (modularized for adaptability)
source "$(dirname "$0")/ui_theme.sh"

# --- Matrix Rain: Echoing the collapse of data streams ---
matrix_rain() {
    local duration=${1:-10}
    local charset=("@", "#", "$", "%", "&", "*", "+", "-")  # Customizable glyphs
    local density=$((COLUMNS / 10))  # Characters per row recalibrated for recursive density

    local end_time=$((SECONDS + duration))
    tput sc; tput civis

    while [ $SECONDS -lt $end_time ]; do
        for ((i = 0; i < density; i++)); do
            local x=$((RANDOM % COLUMNS))
            local char="${charset[RANDOM % ${#charset[@]}]}"
            tput cup $((RANDOM % LINES)) $x
            echo -en "${UI_COLORS[primary]}$char${UI_COLORS[reset]}"
        done
        sleep 0.05
    done

    tput rc; tput cnorm
}

# --- Interactive Progress Bar: Time's arrow moving forward ---
progress_bar() {
    local current=$1
    local total=$2
    local label=${3:-"Progress"}
    local width=$((COLUMNS - 20))  # Dynamic recalibration for terminal size
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))

    printf "\r${UI_COLORS[info]}%s:${UI_COLORS[reset]} [" "$label"
    printf "%${filled}s" | tr " " "█"
    printf "%${empty}s" | tr " " "░"
    printf "] %3d%%" $percentage
}

# --- Spinner: Recursive cycles of waiting ---
spinner() {
    local pid=$1
    local message=${2:-"Loading"}
    local timeout=${3:-30}  # Recursive timer (fail-safe)
    local spinner_set=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local end_time=$((SECONDS + timeout))

    while kill -0 $pid 2>/dev/null && [ $SECONDS -lt $end_time ]; do
        for frame in "${spinner_set[@]}"; do
            printf "\r${UI_COLORS[primary]}%s${UI_COLORS[reset]} %s" "$frame" "$message"
            sleep 0.1
        done
    done

    printf "\r${UI_COLORS[success]}Done!${UI_COLORS[reset]}\n"
}

# --- Status Messages: Echoing validation ---
ui_success() { echo -e "${UI_COLORS[success]}${UI_SYMBOLS[success]} $1${UI_COLORS[reset]}"; }
ui_error() { echo -e "${UI_COLORS[error]}${UI_SYMBOLS[error]} $1${UI_COLORS[reset]}"; }
ui_warning() { echo -e "${UI_COLORS[warning]}${UI_SYMBOLS[warning]} $1${UI_COLORS[reset]}"; }
ui_info() { echo -e "${UI_COLORS[info]}${UI_SYMBOLS[info]} $1${UI_COLORS[reset]}"; }

# --- Interactive Menu: Recursive branching of options ---
ui_menu() {
    local title=$1
    shift
    local options=("$@")
    local selected=0
    local key

    while true; do
        clear
        echo -e "${UI_COLORS[primary]}$title${UI_COLORS[reset]}\n"

        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "${UI_COLORS[primary]}${UI_SYMBOLS[arrow]} ${options[i]}${UI_COLORS[reset]}"
            else
                echo -e "${UI_COLORS[muted]}  ${options[i]}${UI_COLORS[reset]}"
            fi
        done

        read -rsn1 key
        case "$key" in
            $'\x1B')
                read -rsn2 key
                case "$key" in
                    '[A') ((selected--)) ;;  # Navigate up the recursive tree
                    '[B') ((selected++)) ;;  # Navigate down the recursive tree
                esac
                ;;
            '') break ;;  # Select current node
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

    while true; do
        printf "${UI_COLORS[primary]}${UI_SYMBOLS[bullet]} %s [y/n] ${UI_COLORS[reset]}" "$message"
        read -r -n 1 response
        echo

        case "$response" in
            [yY]) return 0 ;;
            [nN]) return 1 ;;
            '') [ "$default" = "y" ] && return 0 || return 1 ;;
            *) ui_error "Please answer y or n" ;;
        esac
    done
}

# --- Example Usage ---
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    ui_menu "Choose an option:" "Option 1" "Option 2" "Quit"
    choice=$?
    echo "You selected option $choice"
fi
