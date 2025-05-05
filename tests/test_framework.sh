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

# SECURITY FIX: Replace eval with array-based execution
run_test() {
    local test_function="$1"
    shift
    local test_args=("$@")
    
    # Execute test in subshell with arguments
    (
        if [ ${#test_args[@]} -gt 0 ]; then
            "$test_function" "${test_args[@]}"
        else
            "$test_function"
        fi
    )
    return $?
}

# Run a test case
it() {
    local description="$1"
    local test_function="$2"
    shift 2
    local test_args=("$@")
    
    ((TESTS_TOTAL++))
    echo -n "  Testing: $description... "
    
    # SECURITY FIX: Use array-based execution instead of eval
    if run_test "$test_function" "${test_args[@]}"; then
        echo -e "${TEST_COLORS[pass]}PASSED${TEST_COLORS[reset]}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${TEST_COLORS[fail]}FAILED${TEST_COLORS[reset]}"
        ((TESTS_FAILED++))
        return 1
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
    
    # SECURITY FIX: Use more restricted command execution
    if [[ $command =~ ^[a-zA-Z0-9_/.\ -]+$ ]]; then
        # Only allow alphanumeric characters, underscores, slashes, dots, spaces and hyphens
        if ! eval "$command"; then
            echo "Assert failed: $message"
            echo "Command: $command"
            return 1
        fi
    else
        echo "Security violation: Command contains unsafe characters"
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

# Generate a test report
generate_report() {
    local report_file="${TEST_OUTPUT_DIR}/report_$(date '+%Y%m%d%H%M%S').txt"
    
    {
        echo "Test Report: $(date)"
        echo "===================="
        echo "Total tests: $TESTS_TOTAL"
        echo "Passed: $TESTS_PASSED"
        echo "Failed: $TESTS_FAILED"
        echo
        echo "Test Suites:"
        # List test suites here
    } > "$report_file"
    
    echo "Report generated: $report_file"
}
