#!/data/data/com.termux/files/usr/bin/bash

# Colors
BOLD="\033[1m"
NC="\033[0m"

# Source the libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/compress.sh"

# Test compression with different quality levels
echo -e "\n${BOLD}Testing PDF Compression${NC}"
echo -e "=====================\n"

for quality in high medium low; do
    echo -e "${BOLD}Testing Quality: ${quality}${NC}"
    echo -e "-------------------"
    cp test_source.pdf "test_${quality}.pdf"
    compress_pdf "test_${quality}.pdf" "$quality"
    mv "test_${quality}_compressed.pdf" "result_${quality}.pdf"
    echo "Output: result_${quality}.pdf"
    echo -e "-------------------\n"
done

echo -e "${BOLD}Results:${NC}"
ls -lh result_*.pdf
