#!/data/data/com.termux/files/usr/bin/bash

# Security audit tool for CompressKit
# Scans codebase for security issues and non-compliance with security standards

# Set up paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
RESET="\033[0m"

# Initialize counters
ISSUES_FOUND=0
FILES_SCANNED=0

# Display header
echo -e "${BLUE}================================${RESET}"
echo -e "${BLUE}CompressKit Security Audit Tool${RESET}"
echo -e "${BLUE}================================${RESET}\n"

# Function to check file for security issues
audit_file() {
    local file="$1"
    local issues=0
    
    echo -e "${MAGENTA}Scanning${RESET}: $file"
    
    # Check for unsafe path handling (without safe_path)
    local unsafe_path_count=$(grep -E '(cat|rm|cp|mv|echo|printf|tee).*>.*\$' "$file" | grep -v 'safe_path' | wc -l)
    if [ "$unsafe_path_count" -gt 0 ]; then
        echo -e "  ${RED}[HIGH]${RESET} Potential unsafe path handling without safe_path(): $unsafe_path_count instances"
        grep -n -E '(cat|rm|cp|mv|echo|printf|tee).*>.*\$' "$file" | grep -v 'safe_path' | head -5 | while read line; do
            echo "    Line: $line"
        done
        ((issues++))
    fi
    
    # Check for eval usage
    local eval_count=$(grep -E '\beval\b' "$file" | grep -v 'safe_execute' | wc -l)
    if [ "$eval_count" -gt 0 ]; then
        echo -e "  ${RED}[HIGH]${RESET} Direct eval usage detected: $eval_count instances"
        grep -n -E '\beval\b' "$file" | grep -v 'safe_execute' | head -5 | while read line; do
            echo "    Line: $line"
        done
        ((issues++))
    fi
    
    # Check for mkdir without permission setting
    local mkdir_count=$(grep -E '\bmkdir\b' "$file" | grep -v 'chmod' | wc -l)
    if [ "$mkdir_count" -gt 0 ]; then
        echo -e "  ${YELLOW}[MEDIUM]${RESET} mkdir without permission setting: $mkdir_count instances"
        ((issues++))
    fi
    
    # Check for direct command execution
    local cmd_exec_count=$(grep -E '\`.*\`|\$\(.*\)' "$file" | grep -v 'safe_execute' | wc -l)
    if [ "$cmd_exec_count" -gt 0 ]; then
        echo -e "  ${RED}[HIGH]${RESET} Direct command execution: $cmd_exec_count instances"
        grep -n -E '\`.*\`|\$\(.*\)' "$file" | grep -v 'safe_execute' | head -5 | while read line; do
            echo "    Line: $line"
        done
        ((issues++))
    fi
    
    # Check for weak error handling
    local error_check_count=$(grep -E '\b(if|then)\b.*\$\?' "$file" | wc -l)
    local command_count=$(grep -E '\b(cp|mv|rm|mkdir|touch)\b' "$file" | wc -l)
    if [ "$command_count" -gt 0 ] && [ "$error_check_count" -lt "$command_count" ]; then
        echo -e "  ${YELLOW}[MEDIUM]${RESET} Potential insufficient error checking"
        ((issues++))
    fi
    
    # Report file results
    if [ "$issues" -eq 0 ]; then
        echo -e "  ${GREEN}No issues found${RESET}\n"
    else
        echo -e "  ${RED}$issues issues found${RESET}\n"
        ((ISSUES_FOUND += issues))
    fi
    
    ((FILES_SCANNED++))
}

# Scan each shell script in the project
find "$PROJECT_ROOT" -type f -name "*.sh" | while read file; do
    audit_file "$file"
done

# Final summary
echo -e "${BLUE}===========================${RESET}"
echo -e "${BLUE}Security Audit Complete${RESET}"
echo -e "${BLUE}===========================${RESET}"
echo -e "Files scanned: $FILES_SCANNED"
if [ "$ISSUES_FOUND" -eq 0 ]; then
    echo -e "${GREEN}No security issues found!${RESET}"
else
    echo -e "${RED}Security issues found: $ISSUES_FOUND${RESET}"
fi
echo

# Exit with status code based on issues found
[ "$ISSUES_FOUND" -eq 0 ]
