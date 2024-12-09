#!/data/data/com.termux/files/usr/bin/bash

# Colors
BOLD="\033[1m"
BLUE="\033[0;34m"
NC="\033[0m"

echo -e "${BOLD}PDF Compression Results${NC}"
echo "======================"
echo

echo -e "${BOLD}Original PDF:${NC}"
ls -lh rich_test.pdf | awk '{print "Size: " $5}'
echo

echo -e "${BOLD}Compressed Versions:${NC}"
for quality in high medium low; do
    echo
    echo -e "${BLUE}Quality: $quality${NC}"
    ls -lh "result_${quality}.pdf" | awk '{print "Size: " $5}'
    
    # Get PDF dimensions using ImageMagick
    dimensions=$(identify -format "Dimensions: %wx%h" "result_${quality}.pdf" 2>/dev/null)
    echo "$dimensions"
    echo "----------------------------------------"
done

# Compare files
echo -e "\n${BOLD}File Comparison:${NC}"
echo "----------------------------------------"
echo -e "Original: \t$(ls -lh rich_test.pdf | awk '{print $5}')"
echo -e "High:     \t$(ls -lh result_high.pdf | awk '{print $5}')"
echo -e "Medium:   \t$(ls -lh result_medium.pdf | awk '{print $5}')"
echo -e "Low:      \t$(ls -lh result_low.pdf | awk '{print $5}')"
echo "----------------------------------------"
