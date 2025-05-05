#!/data/data/com.termux/files/usr/bin/bash

# Colors and formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
BOLD="\033[1m"
NC="\033[0m"

# Helper functions
progress() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
separator() { echo -e "\n${BOLD}=== $1 ===${NC}\n"; }

# Test environment setup
setup() {
    separator "Setting Up Test Environment"
    
    # Step 1: Create and verify test directory
    progress "Creating test directory..."
    if ! mkdir -p test_files; then
        error "Failed to create test directory"
        return 1
    fi
    
    # Step 2: Change to test directory with verification
    if ! cd test_files; then
        error "Failed to change to test directory"
        return 1
    fi
    
    # Step 3: Generate test PDF with proper error handling
    progress "Generating test PDF..."
    if ! command -v convert >/dev/null 2>&1; then
        error "ImageMagick not installed"
        return 1
    fi
    
    if ! convert -size 1000x1000 xc:white -gravity center -pointsize 72 -annotate 0 "Test PDF" test.pdf; then
        error "Failed to create test PDF"
        cd ..
        return 1
    fi
    
    # Step 4: Verify PDF was created
    if [ ! -f "test.pdf" ]; then
        error "PDF file not created"
        cd ..
        return 1
    fi
    
    # Step 5: Return to original directory
    if ! cd ..; then
        error "Failed to return to original directory"
        return 1
    fi
    
    success "Test environment ready"
    return 0
}

# Test basic compression
test_basic_compression() {
    separator "Basic Compression Test"
    progress "Testing basic compression functionality..."
    
    # Verify test file exists
    if [ ! -f test_files/test.pdf ]; then
        error "Test PDF not found"
        return 1
    fi
    
    # Run basic compression
    progress "Running compression..."
    if ! ../compresskit-pdf test_files/test.pdf; then
        error "Compression failed"
        return 1
    fi
    
    success "Basic compression test passed"
    return 0
}

# Test quality levels
test_quality_levels() {
    separator "Quality Levels Test"
    local total=3
    local current=0
    
    for level in high medium low; do
        ((current++))
        progress "Testing quality level: $level ($current/$total)"
        
        if ! ../compresskit-pdf -q "$level" test_files/test.pdf; then
            error "Quality level $level test failed"
            return 1
        fi
        success "Quality level $level passed"
    done
    
    success "All quality level tests completed"
    return 0
}

# Clean up test environment
cleanup() {
    separator "Cleanup"
    progress "Removing test files..."
    rm -rf test_files
    success "Cleanup complete"
}

# Main test runner
main() {
    echo -e "\n${BOLD}CompressKit Test Suite${NC}"
    echo -e "------------------------\n"
    
    setup || {
        error "Setup failed"
        exit 1
    }
    
    test_basic_compression || {
        error "Basic compression tests failed"
        cleanup
        exit 1
    }
    
    test_quality_levels || {
        error "Quality level tests failed"
        cleanup
        exit 1
    }
    
    cleanup
    
    separator "Test Summary"
    success "All tests completed successfully"
}

# Run tests
main "$@"
