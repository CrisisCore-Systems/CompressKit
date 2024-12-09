#!/data/data/com.termux/files/usr/bin/bash

# UI Component Library for CompressKit
# Handles all visual elements and user interaction

declare -A UI_COLORS=(
    ["primary"]=$(tput setaf 51)    # Bright Cyan
    ["secondary"]=$(tput setaf 99)   # Purple
    ["success"]=$(tput setaf 46)     # Green
    ["warning"]=$(tput setaf 214)    # Orange
    ["error"]=$(tput setaf 196)      # Red
    ["info"]=$(tput setaf 39)        # Blue
    ["muted"]=$(tput setaf 245)      # Gray
    ["reset"]=$(tput sgr0)
)

declare -A UI_SYMBOLS=(
    ["success"]="✓"
    ["error"]="✗"
    ["warning"]="⚠"
    ["info"]="ℹ"
    ["arrow"]="➜"
    ["bullet"]="•"
    ["check"]="☐"
    ["checked"]="☑"
)

# Matrix rain effect implementation
matrix_rain() {
    local duration=$1
    local end_time=$((SECONDS + duration))
    
    # Save cursor position and hide it
    tput sc
    tput civis
    
    while [ $SECONDS -lt $end_time ]; do
        local x=$((RANDOM % COLUMNS))
        local y=$((RANDOM % LINES))
        tput cup $y $x
        echo -en "${UI_COLORS[primary]}$(printf \\$(printf '%03o' $((RANDOM % 93 + 33))))${UI_COLORS[reset]}"
        sleep 0.01
    done
    
    # Restore cursor position and show it
    tput rc
    tput cnorm
}

# Interactive progress bar
progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${UI_COLORS[muted]}["
    printf "%${filled}s" | tr " " "█"
    printf "%${empty}s" | tr " " "░"
    printf "] %3d%%${UI_COLORS[reset]}" $percentage
}

# Animated spinner
spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local charwidth=3
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spin#?}
        printf "\r${UI_COLORS[primary]}%c${UI_COLORS[reset]} %s" "$spin" "$message"
        spin=$temp${spin%"$temp"}
        sleep 0.1
    done
    printf "\r"
}

# Status message functions
ui_success() { echo -e "${UI_COLORS[success]}${UI_SYMBOLS[success]} $1${UI_COLORS[reset]}"; }
ui_error() { echo -e "${UI_COLORS[error]}${UI_SYMBOLS[error]} $1${UI_COLORS[reset]}"; }
ui_warning() { echo -e "${UI_COLORS[warning]}${UI_SYMBOLS[warning]} $1${UI_COLORS[reset]}"; }
ui_info() { echo -e "${UI_COLORS[info]}${UI_SYMBOLS[info]} $1${UI_COLORS[reset]}"; }

# Interactive menu
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
                    '[A') ((selected--)) ;;  # Up
                    '[B') ((selected++)) ;;  # Down
                esac
                ;;
            '') break ;;
        esac
        
        selected=$((selected % ${#options[@]}))
        [ $selected -lt 0 ] && selected=$((${#options[@]} - 1))
    done
    
    return $selected
}

# Confirmation dialog
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
