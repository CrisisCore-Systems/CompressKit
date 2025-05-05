#!/data/data/com.termux/files/usr/bin/bash

# Test suite for security functions in CompressKit
# Tests the critical security functions to ensure they work properly

# Colors for test output
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Load the security utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/secure_utils.sh"

# Helper function to run tests
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo -e "${BLUE}[TEST]${NC} Running test: ${test_name}"
    ((TESTS_RUN++))
    
    if $test_function; then
        echo -e "${GREEN}[PASS]${NC} Test passed: ${test_name}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}[FAIL]${NC} Test failed: ${test_name}"
        ((TESTS_FAILED++))
    fi
    
    echo
}

# Test safe_path function with all safety levels
test_safe_path() {
    local result
    
    # Test normal path - strict mode
    echo "Testing normal path (strict mode)..."
    result=$(safe_path "/tmp/test.txt" "strict")
    if [ "$result" != "/tmp/test.txt" ]; then
        echo "Normal path test failed: expected '/tmp/test.txt', got '$result'"
        return 1
    fi
    
    # Test path with traversal attempt
    echo "Testing path with traversal attempt..."
    result=$(safe_path "/tmp/../etc/passwd" 2>/dev/null)
    if [[ "$result" == *"/etc/passwd"* ]]; then
        echo "Path traversal prevention failed"
        return 1
    fi
    
    # Test empty path
    echo "Testing empty path..."
    if safe_path "" 2>/dev/null; then
        echo "Empty path validation failed"
        return 1
    fi
    
    # Test path with null bytes
    echo "Testing path with null bytes..."
    if safe_path "/tmp/test.txt$(echo -e '\0')/etc/passwd" 2>/dev/null; then
        echo "Null byte handling failed"
        return 1
    fi
    
    # Test with safety levels
    echo "Testing safety levels..."
    for level in strict normal relaxed; do
        if ! safe_path "/tmp/test.txt" "$level" >/dev/null; then
            echo "Safety level '$level' handling failed"
            return 1
        fi
    done
    
    # Test invalid safety level
    echo "Testing invalid safety level..."
    if safe_path "/tmp/test.txt" "invalid_level" 2>/dev/null; then
        echo "Invalid safety level handling failed"
        return 1
    fi
    
    return 0
}

# Test validate_input function
test_validate_input() {
    # Test valid input
    echo "Testing valid input..."
    if ! validate_input "high" "low" "medium" "high"; then
        echo "Valid input validation failed"
        return 1
    fi
    
    # Test invalid input
    echo "Testing invalid input..."
    if validate_input "invalid" "low" "medium" "high" 2>/dev/null; then
        echo "Invalid input validation failed"
        return 1
    fi
    
    # Test empty input
    echo "Testing empty input..."
    if validate_input "" "low" "medium" "high" 2>/dev/null; then
        echo "Empty input validation failed"
        return 1
    fi
    
    return 0
}

# Test secure_tempfile function
test_secure_tempfile() {
    # Test creating temporary file
    echo "Testing temporary file creation..."
    local temp_file
    temp_file=$(secure_tempfile "test")
    
    if [ $? -ne 0 ] || [ -z "$temp_file" ] || [ ! -f "$temp_file" ]; then
        echo "Failed to create temporary file"
        return 1
    fi
    
    # Test file permissions
    local perms
    perms=$(stat -c "%a" "$temp_file" 2>/dev/null || stat -f "%Lp" "$temp_file" 2>/dev/null)
    
    if [ "$perms" != "600" ]; then
        echo "Temporary file has incorrect permissions: $perms (expected 600)"
        rm -f "$temp_file"
        return 1
    fi
    
    # Clean up
    rm -f "$temp_file"
    return 0
}

# Test safe_execute function
test_safe_execute() {
    # Test normal command execution
    echo "Testing normal command execution..."
    local result
    result=$(safe_execute "echo test")
    
    if [ "$result" != "test" ]; then
        echo "Command execution failed: expected 'test', got '$result'"
        return 1
    fi
    
    # Test command with arguments containing spaces
    echo "Testing command with space in arguments..."
    result=$(safe_execute "echo \"hello world\"")
    
    if [ "$result" != "hello world" ]; then
        echo "Command execution with quoted arguments failed: expected 'hello world', got '$result'"
        return 1
    fi
    
    # Test empty command
    echo "Testing empty command..."
    if safe_execute "" 2>/dev/null; then
        echo "Empty command validation failed"
        return 1
    fi
    
    # Test disallowed command
    echo "Testing disallowed command..."
    if safe_execute "sudo rm -rf /" 2>/dev/null; then
        echo "Disallowed command validation failed"
        return 1
    fi
    
    return 0
}

# Test sanitize_string function
test_sanitize_string() {
    echo "Testing string sanitization..."
    
    # Test basic sanitization
    local input="Hello World!"
    local expected="Hello World!"
    local result
    result=$(sanitize_string "$input")
    
    if [ "$result" != "$expected" ]; then
        echo "Basic sanitization failed: expected '$expected', got '$result'"
        return 1
    fi
    
    # Test command injection attempt
    input="Hello \`rm -rf /\`; World"
    expected="Hello ; World"
    result=$(sanitize_string "$input")
    
    if [[ "$result" == *"\`"* || "$result" == *"rm"* ]]; then
        echo "Command injection sanitization failed: got '$result'"
        return 1
    fi
    
    # Test SQL injection attempt
    input="name' OR 1=1 --"
    result=$(sanitize_string "$input")
    
    if [[ "$result" == *"'"* && "$result" == *"--"* ]]; then
        echo "SQL injection sanitization failed: got '$result'"
        return 1
    fi
    
    return 0
}

# Test path traversal edge cases
test_path_traversal_edge_cases() {
    echo "Testing path traversal edge cases..."
    
    # Test Unicode right-to-left override character
    local path="malicious$(echo -e '\u202E')fdp.txt"
    if safe_path "$path" 2>/dev/null; then
        echo "Unicode RTL override test failed"
        return 1
    fi
    
    # Test long paths
    local long_path=$(printf '/tmp/%0255d' 1)
    local result
    result=$(safe_path "$long_path" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Long path handling failed"
        return 1
    fi
    
    # Test double-dot sequence with encoding
    if safe_path "/tmp/..%2f..%2fetc/passwd" 2>/dev/null; then
        echo "Encoded traversal test failed"
        return 1
    fi
    
    return 0
}

# Run all tests
echo -e "${BLUE}Running CompressKit Security Function Tests${NC}"
echo "==============================================="
echo

run_test "safe_path" test_safe_path
run_test "validate_input" test_validate_input
run_test "secure_tempfile" test_secure_tempfile
run_test "safe_execute" test_safe_execute
run_test "sanitize_string" test_sanitize_string
run_test "path_traversal_edge_cases" test_path_traversal_edge_cases

# Print summary
echo "==============================================="
echo -e "${BLUE}Test Summary${NC}"
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"

# Return appropriate exit code
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
