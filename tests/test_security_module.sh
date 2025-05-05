#!/data/data/com.termux/files/usr/bin/bash

# Test suite for the consolidated security module
# Performs comprehensive tests of all security functions

# Colors for test output
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
BOLD="\033[1m"
NC="\033[0m"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Load the security module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/security_module.sh"

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

# Helper function to skip tests
skip_test() {
    local test_name="$1"
    local reason="$2"
    
    echo -e "${YELLOW}[SKIP]${NC} Skipping test: ${test_name}"
    echo "       Reason: $reason"
    ((TESTS_SKIPPED++))
    
    echo
}

# Test safe_path function with full range of inputs
test_safe_path() {
    echo "Testing safe_path function with various inputs..."
    local result
    
    # Test normal valid paths
    echo "1. Testing normal path handling..."
    result=$(safe_path "/tmp/test.txt")
    if [ "$result" != "/tmp/test.txt" ]; then
        echo "Normal path test failed: expected '/tmp/test.txt', got '$result'"
        return 1
    fi
    
    # Test path traversal attacks
    echo "2. Testing path traversal prevention..."
    if safe_path "/tmp/../etc/passwd" &>/dev/null; then
        echo "Path traversal prevention failed (../)"
        return 1
    fi
    
    if safe_path "/tmp/something/../../etc/shadow" &>/dev/null; then
        echo "Path traversal prevention failed (multiple ../)"
        return 1
    fi
    
    if safe_path "/tmp/./././something" &>/dev/null; then
        echo "Path traversal prevention failed (multiple ./)"
        return 1
    fi
    
    # Test null byte injection
    echo "3. Testing null byte handling..."
    if safe_path "/tmp/test.txt$(echo -e '\0')/etc/passwd" &>/dev/null; then
        echo "Null byte handling failed"
        return 1
    fi
    
    # Test URL encoded attacks
    echo "4. Testing URL encoding handling..."
    if safe_path "/tmp/%2e%2e/etc/passwd" &>/dev/null; then
        echo "URL encoded traversal test failed"
        return 1
    fi
    
    # Test safety levels
    echo "5. Testing different safety levels..."
    for level in strict normal relaxed; do
        if ! safe_path "/tmp/valid_file.txt" "$level" >/dev/null; then
            echo "Safety level '$level' handling failed for valid path"
            return 1
        fi
    done
    
    # Test with invalid safety level
    echo "6. Testing invalid safety level..."
    if safe_path "/tmp/test.txt" "invalid_level" &>/dev/null; then
        echo "Invalid safety level handling failed"
        return 1
    fi
    
    # Test with sensitive system paths depending on safety level
    echo "7. Testing sensitive path handling..."
    if safe_path "/etc/shadow" "strict" &>/dev/null; then
        echo "Sensitive file protection failed (strict level)"
        return 1
    fi
    
    if safe_path "/etc/shadow" "normal" &>/dev/null; then
        echo "Sensitive file protection failed (normal level)"
        return 1
    fi
    
    # Relaxed should allow sensitive paths
    if ! safe_path "/etc/hosts" "relaxed" &>/dev/null; then
        echo "Relaxed mode incorrectly blocks non-sensitive system file"
        return 1
    fi
    
    # Test symlink handling (only if we can create symlinks)
    echo "8. Testing symlink handling..."
    if command -v ln &>/dev/null; then
        # Create a test directory and symlink
        mkdir -p "/tmp/security_test_dir"
        touch "/tmp/security_test_dir/target.txt"
        ln -sf "/tmp/security_test_dir/target.txt" "/tmp/security_test_dir/symlink.txt"
        
        # Symlinks should be allowed in non-sensitive directories
        if ! safe_path "/tmp/security_test_dir/symlink.txt" "strict" &>/dev/null; then
            echo "Symlink incorrectly blocked in non-sensitive directory"
            rm -rf "/tmp/security_test_dir"
            return 1
        fi
        
        # Clean up
        rm -rf "/tmp/security_test_dir"
    else
        echo "Skipping symlink test - 'ln' command not available"
    fi
    
    return 0
}

# Test safe_execute function
test_safe_execute() {
    echo "Testing safe_execute function..."
    local result
    
    # Test basic command execution
    echo "1. Testing basic command execution..."
    result=$(safe_execute "echo test")
    if [ "$result" != "test" ]; then
        echo "Basic command execution failed: expected 'test', got '$result'"
        return 1
    fi
    
    # Test with complex arguments
    echo "2. Testing command with complex arguments..."
    result=$(safe_execute "echo \"hello world with spaces\"")
    if [ "$result" != "hello world with spaces" ]; then
        echo "Command with complex arguments failed: expected 'hello world with spaces', got '$result'"
        return 1
    fi
    
    # Test command whitelist enforcement
    echo "3. Testing command whitelist enforcement..."
    if safe_execute "sudo rm -rf /" &>/dev/null; then
        echo "Command whitelist enforcement failed - allowed dangerous command"
        return 1
    fi
    
    if safe_execute "not_a_real_command" &>/dev/null; then
        echo "Command whitelist enforcement failed - allowed non-existent command"
        return 1
    fi
    
    # Test empty command
    echo "4. Testing empty command rejection..."
    if safe_execute "" &>/dev/null; then
        echo "Empty command validation failed"
        return 1
    fi
    
    # Test pipeline command (should fail as not in whitelist)
    echo "5. Testing pipeline command rejection..."
    if safe_execute "cat /dev/null | grep something" &>/dev/null; then
        echo "Pipeline command validation failed"
        return 1
    fi
    
    return 0
}

# Test secure_tempfile function
test_secure_tempfile() {
    echo "Testing secure_tempfile function..."
    
    # Test basic temporary file creation
    echo "1. Testing basic temporary file creation..."
    local temp_file
    temp_file=$(secure_tempfile "test")
    
    if [ $? -ne 0 ] || [ -z "$temp_file" ] || [ ! -f "$temp_file" ]; then
        echo "Basic temporary file creation failed"
        return 1
    fi
    
    # Test file permissions
    echo "2. Testing temporary file permissions..."
    local perms
    perms=$(stat -c "%a" "$temp_file" 2>/dev/null || stat -f "%Lp" "$temp_file" 2>/dev/null)
    
    if [ "$perms" != "600" ]; then
        echo "Temporary file has incorrect permissions: $perms (expected 600)"
        rm -f "$temp_file"
        return 1
    fi
    
    # Test with custom prefix
    echo "3. Testing custom prefix..."
    local prefix="custom_prefix"
    local custom_temp_file
    custom_temp_file=$(secure_tempfile "$prefix")
    
    if [ $? -ne 0 ] || [ -z "$custom_temp_file" ] || [ ! -f "$custom_temp_file" ]; then
        echo "Temporary file creation with custom prefix failed"
        rm -f "$temp_file"
        return 1
    fi
    
    # Check if prefix is used
    if [[ ! "$custom_temp_file" == *"$prefix"* ]]; then
        echo "Custom prefix not found in temporary filename: $custom_temp_file"
        rm -f "$temp_file" "$custom_temp_file"
        return 1
    fi
    
    # Clean up
    rm -f "$temp_file" "$custom_temp_file"
    return 0
}

# Test validate_input function
test_validate_input() {
    echo "Testing validate_input function..."
    
    # Test with valid input
    echo "1. Testing with valid input..."
    if ! validate_input "high" "low" "medium" "high"; then
        echo "Valid input validation failed"
        return 1
    fi
    
    # Test with invalid input
    echo "2. Testing with invalid input..."
    if validate_input "invalid" "low" "medium" "high" &>/dev/null; then
        echo "Invalid input validation failed"
        return 1
    fi
    
    # Test with empty input
    echo "3. Testing with empty input..."
    if validate_input "" "low" "medium" "high" &>/dev/null; then
        echo "Empty input validation failed"
        return 1
    fi
    
    # Test case sensitivity
    echo "4. Testing case sensitivity..."
    if validate_input "HIGH" "low" "medium" "high" &>/dev/null; then
        echo "Case sensitivity validation failed"
        return 1
    fi
    
    return 0
}

# Test validate_numeric function
test_validate_numeric() {
    echo "Testing validate_numeric function..."
    
    # Test with valid numeric input
    echo "1. Testing with valid numeric input..."
    if ! validate_numeric "42"; then
        echo "Valid numeric input validation failed"
        return 1
    fi
    
    # Test with non-numeric input
    echo "2. Testing with non-numeric input..."
    if validate_numeric "not-a-number" &>/dev/null; then
        echo "Non-numeric input validation failed"
        return 1
    fi
    
    # Test with valid range
    echo "3. Testing with valid range..."
    if ! validate_numeric "42" "1" "100"; then
        echo "Valid range validation failed"
        return 1
    fi
    
    # Test with below minimum
    echo "4. Testing with below minimum..."
    if validate_numeric "5" "10" "100" &>/dev/null; then
        echo "Below minimum validation failed"
        return 1
    fi
    
    # Test with above maximum
    echo "5. Testing with above maximum..."
    if validate_numeric "150" "1" "100" &>/dev/null; then
        echo "Above maximum validation failed"
        return 1
    fi
    
    # Test edge cases
    echo "6. Testing edge cases..."
    if ! validate_numeric "10" "10" "20"; then
        echo "Minimum edge case validation failed"
        return 1
    fi
    
    if ! validate_numeric "20" "10" "20"; then
        echo "Maximum edge case validation failed"
        return 1
    fi
    
    return 0
}

# Test sanitize_string function
test_sanitize_string() {
    echo "Testing sanitize_string function..."
    
    # Test with normal text
    echo "1. Testing with normal text..."
    local input="Hello World!"
    local expected="Hello World!"
    local result
    result=$(sanitize_string "$input")
    
    if [ "$result" != "$expected" ]; then
        echo "Normal text sanitization failed: expected '$expected', got '$result'"
        return 1
    fi
    
    # Test with command injection attempts
    echo "2. Testing with command injection attempts..."
    input="Hello \`rm -rf /\`; World"
    result=$(sanitize_string "$input")
    
    if [[ "$result" == *"\`"* || "$result" == *"rm -rf /"* ]]; then
        echo "Command injection sanitization failed: got '$result'"
        return 1
    fi
    
    input='$(rm -rf /)'
    result=$(sanitize_string "$input")
    
    if [[ "$result" == *"$("* || "$result" == *"rm -rf /"* ]]; then
        echo "Command substitution sanitization failed: got '$result'"
        return 1
    fi
    
    # Test with SQL injection attempts
    echo "3. Testing with SQL injection attempts..."
    input="name' OR 1=1 --"
    result=$(sanitize_string "$input")
    
    if [[ "$result" == *"'"* && "$result" == *"--"* ]]; then
        echo "SQL injection sanitization failed: got '$result'"
        return 1
    fi
    
    # Test with HTML/script injection
    echo "4. Testing with HTML/script injection..."
    input="<script>alert('XSS')</script>"
    result=$(sanitize_string "$input")
    
    if [[ "$result" == *"<script>"* || "$result" == *"alert"* ]]; then
        echo "HTML injection sanitization failed: got '$result'"
        return 1
    fi
    
    return 0
}

# Test safe_write_file function
test_safe_write_file() {
    echo "Testing safe_write_file function..."
    
    # Set up test directory
    local test_dir="/tmp/security_test_write"
    mkdir -p "$test_dir"
    
    # Test basic file writing
    echo "1. Testing basic file writing..."
    local test_file="${test_dir}/test.txt"
    local test_content="This is test content"
    
    if ! safe_write_file "$test_file" "$test_content" "644"; then
        echo "Basic file writing failed"
        rm -rf "$test_dir"
        return 1
    fi
    
    # Check if content was written correctly
    if [ ! -f "$test_file" ] || [ "$(cat "$test_file")" != "$test_content" ]; then
        echo "File content verification failed"
        rm -rf "$test_dir"
        return 1
    fi
    
    # Check file permissions
    local perms
    perms=$(stat -c "%a" "$test_file" 2>/dev/null || stat -f "%Lp" "$test_file" 2>/dev/null)
    
    if [ "$perms" != "644" ]; then
        echo "File permissions verification failed: expected 644, got $perms"
        rm -rf "$test_dir"
        return 1
    fi
    
    # Test path traversal prevention
    echo "2. Testing path traversal prevention..."
    if safe_write_file "${test_dir}/../dangerous.txt" "Dangerous content" &>/dev/null; then
        echo "Path traversal prevention failed"
        rm -rf "$test_dir"
        # Check and clean up the file if it was created
        if [ -f "/tmp/dangerous.txt" ]; then
            rm -f "/tmp/dangerous.txt"
        fi
        return 1
    fi
    
    # Test automatic directory creation
    echo "3. Testing automatic directory creation..."
    local nested_file="${test_dir}/nested/dirs/test.txt"
    if ! safe_write_file "$nested_file" "Nested content" "600"; then
        echo "Automatic directory creation failed"
        rm -rf "$test_dir"
        return 1
    fi
    
    # Verify nested directories and file were created
    if [ ! -f "$nested_file" ] || [ "$(cat "$nested_file")" != "Nested content" ]; then
        echo "Nested file verification failed"
        rm -rf "$test_dir"
        return 1
    fi
    
    # Clean up
    rm -rf "$test_dir"
    return 0
}

# Test safe_send_email function
test_safe_send_email() {
    echo "Testing safe_send_email function..."
    
    # Check if mail command is available - if not, skip this test
    if ! command -v mail &>/dev/null; then
        echo "Skipping email test - mail command not available"
        skip_test "safe_send_email" "mail command not available"
        return 0
    fi
    
    # Test email validation
    echo "1. Testing email validation..."
    if safe_send_email "not-an-email" "Test Subject" "Test Body" &>/dev/null; then
        echo "Email validation failed - accepted invalid address"
        return 1
    fi
    
    if safe_send_email "" "Test Subject" "Test Body" &>/dev/null; then
        echo "Email validation failed - accepted empty address"
        return 1
    fi
    
    # Testing with a valid format email (but not sending)
    # We're just checking the validation logic here
    local valid_email="test@example.com"
    
    # Mock the actual mail command to avoid sending real emails
    mail() {
        return 0
    }
    
    if ! safe_send_email "$valid_email" "Test Subject" "Test Body"; then
        echo "Email validation failed - rejected valid address"
        return 1
    fi
    
    # Test subject sanitization
    echo "2. Testing subject sanitization..."
    if ! safe_send_email "$valid_email" "Normal Subject" "Test Body"; then
        echo "Subject sanitization failed - rejected normal subject"
        return 1
    fi
    
    if ! safe_send_email "$valid_email" "Subject with \`dangerous\` characters" "Test Body"; then
        echo "Subject sanitization failed - rejected sanitizable subject"
        return 1
    fi
    
    return 0
}

# Test check_file_permissions function
test_check_file_permissions() {
    echo "Testing check_file_permissions function..."
    
    # Set up test file
    local test_file="/tmp/security_test_perms"
    echo "test content" > "$test_file"
    
    # Set different permissions and test
    echo "1. Testing with matching permissions..."
    chmod 640 "$test_file"
    
    if ! check_file_permissions "$test_file" "640"; then
        echo "Permission check failed - should match exactly"
        rm -f "$test_file"
        return 1
    fi
    
    echo "2. Testing with more restrictive permissions..."
    chmod 600 "$test_file"
    
    if ! check_file_permissions "$test_file" "640"; then
        echo "Permission check failed - should accept more restrictive"
        rm -f "$test_file"
        return 1
    fi
    
    echo "3. Testing with less restrictive permissions..."
    chmod 644 "$test_file"
    
    if check_file_permissions "$test_file" "640" &>/dev/null; then
        echo "Permission check failed - should reject less restrictive"
        rm -f "$test_file"
        return 1
    fi
    
    # Test with nonexistent file
    echo "4. Testing with nonexistent file..."
    if check_file_permissions "/tmp/nonexistent-file-12345" "640" &>/dev/null; then
        echo "File existence check failed"
        rm -f "$test_file"
        return 1
    fi
    
    # Clean up
    rm -f "$test_file"
    return 0
}

# Test report_security_incident function
test_report_security_incident() {
    echo "Testing report_security_incident function..."
    
    # Set up test directory
    local security_dir="${HOME}/.config/compresskit/security"
    local old_incidents=()
    
    # Capture existing incident files to avoid removing them
    if [ -d "$security_dir" ]; then
        old_incidents=("${security_dir}"/incident_*.log)
    fi
    
    # Test basic incident reporting
    echo "1. Testing basic incident reporting..."
    if ! report_security_incident "TEST_INCIDENT" "This is a test incident"; then
        echo "Basic incident reporting failed"
        return 1
    fi
    
    # Check if incident file was created
    local new_incidents=()
    new_incidents=("${security_dir}"/incident_*.log)
    
    local new_file=""
    for file in "${new_incidents[@]}"; do
        if [[ ! " ${old_incidents[*]} " =~ " ${file} " ]]; then
            new_file="$file"
            break
        fi
    done
    
    if [ -z "$new_file" ] || [ ! -f "$new_file" ]; then
        echo "Incident file was not created"
        return 1
    fi
    
    # Check file content
    if ! grep -q "TEST_INCIDENT" "$new_file" || ! grep -q "This is a test incident" "$new_file"; then
        echo "Incident file has incorrect content"
        cat "$new_file"
        rm -f "$new_file"
        return 1
    fi
    
    # Check file permissions
    local perms
    perms=$(stat -c "%a" "$new_file" 2>/dev/null || stat -f "%Lp" "$new_file" 2>/dev/null)
    
    if [ "$perms" != "600" ]; then
        echo "Incident file has incorrect permissions: $perms (expected 600)"
        rm -f "$new_file"
        return 1
    fi
    
    # Clean up the test incident file
    rm -f "$new_file"
    
    return 0
}

# Run all tests
echo -e "${BOLD}CompressKit Security Module Test Suite${NC}"
echo "=============================================="
echo

run_test "safe_path" test_safe_path
run_test "safe_execute" test_safe_execute
run_test "secure_tempfile" test_secure_tempfile
run_test "validate_input" test_validate_input
run_test "validate_numeric" test_validate_numeric
run_test "sanitize_string" test_sanitize_string
run_test "safe_write_file" test_safe_write_file
run_test "check_file_permissions" test_check_file_permissions
run_test "report_security_incident" test_report_security_incident

# Only run email test if mail command is available
if command -v mail &>/dev/null; then
    run_test "safe_send_email" test_safe_send_email
else
    skip_test "safe_send_email" "mail command not available"
fi

# Print summary
echo "=============================================="
echo -e "${BOLD}Test Summary${NC}"
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo "Tests skipped: $TESTS_SKIPPED"

# Return appropriate exit code
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
