#!/data/data/com.termux/files/usr/bin/bash

# Test framework for CompressKit

# Test result counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test suite information
CURRENT_SUITE=""
TEST_OUTPUT_DIR="tests/output"

# Colors for test output
TEST_COLORS=(
    ["pass"]=$(tput setaf 2)
    ["fail"]=$(tput setaf 1)
    ["info"]=$(tput setaf 4)
    ["reset"]=$(tput sgr0)
)

# Initialize test environment
init_tests() {
    # Create test output directory
    mkdir -p "$TEST_OUTPUT_DIR"
    
    # Clean previous test results
    rm -f "${TEST_OUTPUT_DIR}"/*
    
    echo "Initializing test environment..."
    echo "================================"
}

# Start a test suite
describe() {
    CURRENT_SUITE="$1"
    echo -e "\n${TEST_COLORS[info]}Test Suite: $CURRENT_SUITE${TEST_COLORS[reset]}"
}

# Run a test case
it() {
    local description="$1"
    local test_function="$2"
    
    ((TESTS_TOTAL++))
    
    # Run test in subshell to isolate environment
    if (set -e; $test_function) > "${TEST_OUTPUT_DIR}/test_${TESTS_TOTAL}.log" 2>&1; then
        echo -e "  ${TEST_COLORS[pass]}✓${TEST_COLORS[reset]} $description"
        ((TESTS_PASSED++))
    else
        echo -e "  ${TEST_COLORS[fail]}✗${TEST_COLORS[reset]} $description"
        echo "    See: ${TEST_OUTPUT_DIR}/test_${TESTS_TOTAL}.log"
        ((TESTS_FAILED++))
    fi
}

# Assert functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values are not equal}"
    
    if [ "$expected" != "$actual" ]; then
        echo "Assert failed: $message"
        echo "Expected: $expected"
        echo "Actual: $actual"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File does not exist}"
    
    if [ ! -f "$file" ]; then
        echo "Assert failed: $message"
        echo "File: $file"
        return 1
    fi
}

assert_success() {
    local command="$1"
    local message="${2:-Command failed}"
    
    if ! eval "$command"; then
        echo "Assert failed: $message"
        echo "Command: $command"
        return 1
    fi
}

# Print test results
print_test_results() {
    echo -e "\nTest Results"
    echo "============"
    echo "Total: $TESTS_TOTAL"
    echo -e "${TEST_COLORS[pass]}Passed: $TESTS_PASSED${TEST_COLORS[reset]}"
    echo -e "${TEST_COLORS[fail]}Failed: $TESTS_FAILED${TEST_COLORS[reset]}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${TEST_COLORS[pass]}All tests passed!${TEST_COLORS[reset]}"
        return 0
    else
        echo -e "\n${TEST_COLORS[fail]}Some tests failed.${TEST_COLORS[reset]}"
        return 1
    fi
}
