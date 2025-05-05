#!/data/data/com.termux/files/usr/bin/bash

# Security testing framework for CompressKit

# Import dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${ROOT_DIR}/lib/secure_utils.sh"
source "${ROOT_DIR}/lib/logger.sh"

# Initialize test counters
SECURITY_TESTS_TOTAL=0
SECURITY_TESTS_PASSED=0
SECURITY_TESTS_FAILED=0

# Test categories
declare -a TEST_CATEGORIES=(
    "path_traversal"
    "command_injection"
    "permission_validation"
    "input_sanitization"
    "configuration_security"
)

# Initialize test environment
init_security_testing() {
    # Create test output directory
    local test_output="${ROOT_DIR}/tests/output/security"
    local safe_dir
    safe_dir=$(safe_path "$test_output")
    
    if [ $? -ne 0 ] || [ -z "$safe_dir" ]; then
        echo "ERROR: Invalid test output directory path"
        return 1
    fi
    
    if ! mkdir -p "$safe_dir" 2>/dev/null; then
        echo "ERROR: Failed to create test output directory"
        return 1
    fi
    
    # Set secure permissions
    chmod 750 "$safe_dir" 2>/dev/null
    
    # Initialize log file for tests
    export SECURITY_TEST_LOG="${safe_dir}/security_tests_$(date '+%Y%m%d%H%M%S').log"
    
    echo "Security Test Framework Initialized: $(date)" > "$SECURITY_TEST_LOG"
    echo "--------------------------------------------" >> "$SECURITY_TEST_LOG"
    
    return 0
}

# Log test results
log_test_result() {
    local test_name="$1"
    local result="$2"
    local details="${3:-No additional details}"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] TEST: $test_name - $result" >> "$SECURITY_TEST_LOG"
    echo "  Details: $details" >> "$SECURITY_TEST_LOG"
}

# Run a security test function and record results
run_security_test() {
    local test_name="$1"
    local test_category="$2"
    local test_function="$3"
    
    echo "Running security test: $test_name ($test_category)"
    
    ((SECURITY_TESTS_TOTAL++))
    
    # Create a subshell to isolate test execution
    if ( $test_function ); then
        echo "✓ PASSED: $test_name"
        log_test_result "$test_name" "PASSED"
        ((SECURITY_TESTS_PASSED++))
        return 0
    else
        echo "✗ FAILED: $test_name"
        log_test_result "$test_name" "FAILED" "Exit code: $?"
        ((SECURITY_TESTS_FAILED++))
        return 1
    fi
}

# Path traversal attack simulation
simulate_path_traversal() {
    local target_function="$1"
    local attack_path="../../../etc/passwd"
    
    # Try to use the function with attack path
    if $target_function "$attack_path" &>/dev/null; then
        echo "VULNERABILITY: $target_function allowed path traversal"
        return 1
    fi
    
    return 0
}

# Command injection attack simulation
simulate_command_injection() {
    local target_function="$1"
    local attack_input="file.txt; echo 'INJECTED COMMAND'"
    
    # Try to use the function with attack input
    if $target_function "$attack_input" 2>&1 | grep -q "INJECTED COMMAND"; then
        echo "VULNERABILITY: $target_function allowed command injection"
        return 1
    fi
    
    return 0
}

# Generate test report
generate_security_test_report() {
    local report_file="${ROOT_DIR}/tests/output/security/report_$(date '+%Y%m%d').md"
    
    {
        echo "# CompressKit Security Test Report"
        echo
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo
        echo "## Summary"
        echo
        echo "- Total tests: $SECURITY_TESTS_TOTAL"
        echo "- Tests passed: $SECURITY_TESTS_PASSED"
        echo "- Tests failed: $SECURITY_TESTS_FAILED"
        echo
        echo "## Details"
        echo
        echo "See log file: $SECURITY_TEST_LOG"
    } > "$report_file"
    
    echo "Security test report generated: $report_file"
}

# Main function to run all security tests
run_all_security_tests() {
    init_security_testing || return 1
    
    echo "Starting CompressKit security tests"
    
    # Import all test modules
    for category in "${TEST_CATEGORIES[@]}"; do
        local test_module="${SCRIPT_DIR}/${category}_tests.sh"
        if [ -f "$test_module" ]; then
            echo "Loading test module: $category"
            source "$test_module"
        else
            echo "Warning: Test module not found: $category"
        fi
    done
    
    # Run all defined tests (populated by imported modules)
    if declare -F | grep -q "^declare -f test_"; then
        for test_func in $(declare -F | grep "^declare -f test_" | cut -d' ' -f3); do
            # Extract category from function name (test_category_name)
            local category=$(echo "$test_func" | cut -d'_' -f2)
            local name=$(echo "$test_func" | cut -d'_' -f3-)
            
            run_security_test "$name" "$category" "$test_func"
        done
    else
        echo "No tests defined!"
    fi
    
    # Generate final report
    generate_security_test_report
    
    echo "Security tests completed: $SECURITY_TESTS_PASSED passed, $SECURITY_TESTS_FAILED failed"
    
    # Return failure if any tests failed
    [ $SECURITY_TESTS_FAILED -eq 0 ]
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_security_tests
fi
