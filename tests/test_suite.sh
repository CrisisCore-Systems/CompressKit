#!/data/data/com.termux/files/usr/bin/bash

# Load test framework
source "tests/test_framework.sh"

# Load system components
source "lib/core.sh"

# Initialize test environment
init_tests

# Configuration tests
describe "Configuration Module"

it "should create default configuration" && {
    create_default_config
    assert_file_exists "$CONFIG_FILE"
}

it "should load configuration correctly" && {
    local test_value=$(get_config "quality")
    assert_equals "medium" "$test_value"
}

# Compression tests
describe "Compression Module"

it "should compress PDF files" && {
    local input_file="tests/samples/test.pdf"
    local output_file="tests/output/compressed.pdf"
    
    # Create test PDF if it doesn't exist
    if [ ! -f "$input_file" ]; then
        convert -size 1000x1000 xc:white "$input_file"
    fi
    
    compress_pdf "$input_file" "high" "$output_file"
    assert_file_exists "$output_file"
}

# UI tests
describe "UI Module"

it "should show progress bar" && {
    local result=$(progress_bar 50 100)
    assert_success "[ -n '$result' ]"
}

# Error handling tests
describe "Error Handler"

it "should handle file not found error" && {
    local result=$(handle_error ${ERROR_CODES["FILE_NOT_FOUND"]} "test_function" "0")
    assert_equals "${ERROR_MESSAGES["FILE_NOT_FOUND"]}" "$(echo "$result" | grep -o "File or directory not found")"
}

# Run all tests
print_test_results
