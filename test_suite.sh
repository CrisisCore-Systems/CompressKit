#!/bin/bash

# CompressKit Test Suite
# A gauntlet of digital torment

source "./lib/compress.sh"
source "./lib/config.sh"

# Test compression with various file sizes
test_compression_sizes() {
    local sizes=(1 5 10)
    for size in "${sizes[@]}"; do
        dd if=/dev/urandom of="test_${size}MB.pdf" bs=1M count=$size 2>/dev/null
        compress_pdf "test_${size}MB.pdf" "high" "."
        [ -f "test_${size}MB_compressed.pdf" ] || { echo "Compression failed for ${size}MB file"; exit 1; }
        rm "test_${size}MB.pdf" "test_${size}MB_compressed.pdf"
    done
    echo "Size variation tests passed, a symphony of shrinking souls"
}

# Test configuration handling
test_config() {
    local qualities=("low" "medium" "high" "ultra")
    for quality in "${qualities[@]}"; do
        echo "Testing quality: $quality" >&2
        set_config "quality" "$quality"
        local got_quality=$(get_config "quality")
        echo "Comparing '$got_quality' with '$quality'" >&2
        [ "$got_quality" = "$quality" ] || { echo "Config test failed for quality: $quality"; exit 1; }
    done
    echo "Config tests passed, the settings bend to our will"
}

# Test error handling
test_error_handling() {
    compress_pdf "non_existent.pdf" "high" "." 2>/dev/null
    [ $? -ne 0 ] || { echo "Error handling failed for non-existent file"; exit 1; }
    echo "Error handling test passed, the void consumes gracefully"
}

# Run all tests
run_tests() {
    test_compression_sizes
    test_config
    test_error_handling
    echo "All tests passed, CompressKit stands unbroken"
}

run_tests
