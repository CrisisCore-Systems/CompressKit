#!/data/data/com.termux/files/usr/bin/bash

# Colors for output
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

# Test setup
setup() {
    echo "Setting up test environment..."
    # Create test PDF
    convert -size 100x100 xc:white test.pdf || {
        echo -e "${RED}Failed to create test PDF${NC}"
        exit 1
    }
}

# Test basic compression
test_basic_compression() {
    echo "Testing basic compression..."
    ../compresskit-pdf test.pdf
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Basic compression test passed${NC}"
    else
        echo -e "${RED}Basic compression test failed${NC}"
        return 1
    fi
}

# Run tests
main() {
    setup
    test_basic_compression
}

main "$@"
