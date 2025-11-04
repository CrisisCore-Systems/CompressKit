# Testing Strategies for Shell Scripts: From Unit Tests to Integration Testing

*Posted: November 4, 2024*  
*Author: CrisisCore-Systems*  
*Tags: Testing, Bash, Quality Assurance, TDD, Shell Scripting*

## Introduction

"Shell scripts don't need tests."

This misconception costs organizations countless hours debugging production failures, investigating security incidents, and dealing with data corruption. The reality is that shell scripts—especially those handling critical operations like file manipulation, system administration, or data processing—need testing just as much as any other code.

**CompressKit** demonstrates that comprehensive testing for shell scripts is not only possible but practical. With over 15 test suites covering unit tests, integration tests, security tests, and edge cases, CompressKit shows how to build confidence in shell script reliability through systematic testing.

In this post, we'll explore the testing strategies, frameworks, and patterns that make CompressKit's test suite comprehensive and maintainable.

## The Testing Challenge

### Why Test Shell Scripts?

Shell scripts present unique testing challenges:

1. **Side Effects**: Scripts interact with the filesystem, processes, and system state
2. **External Dependencies**: Scripts rely on system commands that may not be available
3. **Environment Sensitivity**: Behavior varies based on environment variables, permissions, and system state
4. **Difficult to Mock**: No built-in mocking framework like modern languages
5. **String-Based**: Everything is text, making type errors common

Despite these challenges, testing is essential because:
- Shell scripts often have privileged access
- Bugs can cause data loss or security breaches
- Scripts are hard to debug in production
- Automated tests catch regressions early

### Testing Philosophy

CompressKit's testing approach follows these principles:

1. **Test at Multiple Levels**: Unit, integration, and system tests
2. **Test Security-Critical Functions**: Extra scrutiny for security code
3. **Test Edge Cases**: Especially error conditions
4. **Maintain Test Independence**: Tests don't depend on each other
5. **Make Tests Fast**: Developers run them frequently

## Test Framework Architecture

### The Custom Test Framework

CompressKit implements a lightweight, custom test framework:

```bash
#!/bin/bash
# tests/test_framework.sh

# Test result counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test suite information
CURRENT_SUITE=""

# Colors for test output
TEST_COLORS=(
    ["pass"]=$(tput setaf 2)  # Green
    ["fail"]=$(tput setaf 1)  # Red
    ["info"]=$(tput setaf 4)  # Blue
    ["reset"]=$(tput sgr0)
)

# Initialize test environment
init_tests() {
    TESTS_TOTAL=0
    TESTS_PASSED=0
    TESTS_FAILED=0
    
    # Create test output directory
    mkdir -p tests/output
    rm -rf tests/output/*
    
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
    shift 2
    local test_args=("$@")
    
    ((TESTS_TOTAL++))
    echo -n "  Testing: $description... "
    
    # Run test in subshell to isolate environment
    if (
        if [ ${#test_args[@]} -gt 0 ]; then
            "$test_function" "${test_args[@]}"
        else
            "$test_function"
        fi
    ); then
        echo -e "${TEST_COLORS[pass]}PASSED${TEST_COLORS[reset]}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${TEST_COLORS[fail]}FAILED${TEST_COLORS[reset]}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Print test summary
print_summary() {
    echo -e "\n================================"
    echo "Test Summary:"
    echo "  Total:  $TESTS_TOTAL"
    echo -e "  ${TEST_COLORS[pass]}Passed: $TESTS_PASSED${TEST_COLORS[reset]}"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "  ${TEST_COLORS[fail]}Failed: $TESTS_FAILED${TEST_COLORS[reset]}"
        return 1
    fi
    
    echo -e "\n${TEST_COLORS[pass]}All tests passed!${TEST_COLORS[reset]}"
    return 0
}
```

### Assertion Functions

```bash
# Assert functions for common test patterns

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values are not equal}"
    
    if [ "$expected" != "$actual" ]; then
        echo "FAILED: $message"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
    return 0
}

assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local message="${3:-Values should not be equal}"
    
    if [ "$unexpected" = "$actual" ]; then
        echo "FAILED: $message"
        echo "  Unexpected value: $actual"
        return 1
    fi
    return 0
}

assert_true() {
    local condition="$1"
    local message="${2:-Condition is not true}"
    
    if ! eval "$condition"; then
        echo "FAILED: $message"
        echo "  Condition: $condition"
        return 1
    fi
    return 0
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File does not exist}"
    
    if [ ! -f "$file" ]; then
        echo "FAILED: $message"
        echo "  File: $file"
        return 1
    fi
    return 0
}

assert_file_not_exists() {
    local file="$1"
    local message="${2:-File should not exist}"
    
    if [ -f "$file" ]; then
        echo "FAILED: $message"
        echo "  File: $file"
        return 1
    fi
    return 0
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String not found}"
    
    if [[ ! "$haystack" =~ $needle ]]; then
        echo "FAILED: $message"
        echo "  Haystack: $haystack"
        echo "  Needle:   $needle"
        return 1
    fi
    return 0
}

assert_exit_code() {
    local expected_code="$1"
    local command="$2"
    local message="${3:-Exit code mismatch}"
    
    eval "$command" >/dev/null 2>&1
    local actual_code=$?
    
    if [ $actual_code -ne $expected_code ]; then
        echo "FAILED: $message"
        echo "  Expected exit code: $expected_code"
        echo "  Actual exit code:   $actual_code"
        echo "  Command: $command"
        return 1
    fi
    return 0
}
```

## Unit Testing Patterns

### Testing Pure Functions

Pure functions are the easiest to test—they have no side effects:

```bash
#!/bin/bash
# tests/test_utils.sh

source ./tests/test_framework.sh
source ./lib/utils.sh

describe "Utility Functions"

test_calculate_percentage() {
    local result=$(calculate_percentage 25 100)
    assert_equals "25" "$result" "Percentage calculation"
}

test_format_size() {
    local result=$(format_bytes 1048576)
    assert_equals "1.0M" "$result" "Size formatting"
}

test_validate_number() {
    if validate_number "123"; then
        return 0
    else
        return 1
    fi
}

test_validate_number_invalid() {
    if validate_number "abc"; then
        return 1  # Should fail
    else
        return 0  # Correctly rejected
    fi
}

# Run tests
init_tests
it "calculates percentage correctly" test_calculate_percentage
it "formats file size" test_format_size
it "validates valid numbers" test_validate_number
it "rejects invalid numbers" test_validate_number_invalid
print_summary
```

### Testing Functions with Side Effects

Functions that modify files or system state require careful setup and teardown:

```bash
#!/bin/bash
# tests/test_file_operations.sh

source ./tests/test_framework.sh
source ./lib/file_ops.sh

# Test directory
TEST_DIR="tests/output/file_ops_$$"

setup() {
    mkdir -p "$TEST_DIR"
}

teardown() {
    rm -rf "$TEST_DIR"
}

test_create_file() {
    local test_file="$TEST_DIR/test.txt"
    
    create_file "$test_file" "test content"
    
    assert_file_exists "$test_file"
    assert_equals "test content" "$(cat $test_file)" "File content"
}

test_copy_file() {
    local source="$TEST_DIR/source.txt"
    local dest="$TEST_DIR/dest.txt"
    
    echo "test data" > "$source"
    copy_file "$source" "$dest"
    
    assert_file_exists "$dest"
    assert_equals "$(cat $source)" "$(cat $dest)" "File copied correctly"
}

test_file_permissions() {
    local test_file="$TEST_DIR/perms.txt"
    
    create_secure_file "$test_file"
    
    assert_file_exists "$test_file"
    local perms=$(stat -c %a "$test_file")
    assert_equals "600" "$perms" "File has secure permissions"
}

# Run tests
describe "File Operations"
init_tests

setup
it "creates file with content" test_create_file
teardown

setup
it "copies files correctly" test_copy_file
teardown

setup
it "sets secure permissions" test_file_permissions
teardown

print_summary
```

## Security Testing

### Testing Path Validation

Security functions deserve extra testing attention:

```bash
#!/bin/bash
# tests/test_security.sh

source ./tests/test_framework.sh
source ./lib/security_module.sh

describe "Security: Path Validation"

test_path_traversal_blocked() {
    local attack_patterns=(
        "../../../etc/passwd"
        "..\\..\\..\\windows\\system32"
        "/etc/../etc/passwd"
        "%2e%2e%2fetc%2fpasswd"
    )
    
    for pattern in "${attack_patterns[@]}"; do
        if safe_path "$pattern" >/dev/null 2>&1; then
            echo "FAILED: Pattern '$pattern' was not blocked"
            return 1
        fi
    done
    
    return 0
}

test_null_byte_blocked() {
    local path=$'file\x00.txt'
    
    if safe_path "$path" >/dev/null 2>&1; then
        echo "FAILED: Null byte was not blocked"
        return 1
    fi
    
    return 0
}

test_valid_path_accepted() {
    local temp_file=$(mktemp)
    
    if ! safe_path "$temp_file" >/dev/null 2>&1; then
        rm -f "$temp_file"
        echo "FAILED: Valid path was rejected"
        return 1
    fi
    
    rm -f "$temp_file"
    return 0
}

test_symlink_validation() {
    local temp_file=$(mktemp)
    local link_file="tests/output/link_$$"
    
    ln -s "$temp_file" "$link_file"
    
    # Should accept symlink to safe location
    if ! safe_path "$link_file" >/dev/null 2>&1; then
        rm -f "$temp_file" "$link_file"
        echo "FAILED: Safe symlink was rejected"
        return 1
    fi
    
    rm -f "$temp_file" "$link_file"
    return 0
}

test_sensitive_path_blocked() {
    local sensitive_paths=(
        "/etc/shadow"
        "/etc/passwd"
        "/root/.ssh/id_rsa"
    )
    
    for path in "${sensitive_paths[@]}"; do
        if safe_path "$path" "high" >/dev/null 2>&1; then
            echo "FAILED: Sensitive path '$path' was not blocked"
            return 1
        fi
    done
    
    return 0
}

# Run tests
init_tests
it "blocks path traversal attempts" test_path_traversal_blocked
it "blocks null byte injection" test_null_byte_blocked
it "accepts valid paths" test_valid_path_accepted
it "validates symlinks" test_symlink_validation
it "blocks sensitive paths in high security mode" test_sensitive_path_blocked
print_summary
```

### Testing Command Execution

```bash
test_safe_execute_allowlist() {
    # Test allowed command
    if ! safe_execute "echo test" >/dev/null 2>&1; then
        echo "FAILED: Allowed command was blocked"
        return 1
    fi
    
    # Test blocked command
    if safe_execute "rm -rf /" >/dev/null 2>&1; then
        echo "FAILED: Dangerous command was not blocked"
        return 1
    fi
    
    return 0
}

test_command_injection_prevention() {
    local malicious_input="file.txt; rm -rf /"
    
    # Should not execute the injected command
    if safe_execute "cat $malicious_input" >/dev/null 2>&1; then
        echo "FAILED: Command injection was not prevented"
        return 1
    fi
    
    return 0
}
```

## Integration Testing

### Testing Complete Workflows

Integration tests verify that components work together:

```bash
#!/bin/bash
# tests/test_compression.sh

source ./tests/test_framework.sh
source ./lib/compress.sh
source ./lib/config.sh
source ./lib/logger.sh

TEST_DIR="tests/output/compression_$$"

setup_integration() {
    mkdir -p "$TEST_DIR"
    
    # Create test PDF
    ./tests/create_test_pdf.sh "$TEST_DIR/test.pdf"
}

teardown_integration() {
    rm -rf "$TEST_DIR"
}

test_basic_compression() {
    local input_file="$TEST_DIR/test.pdf"
    local output_file="$TEST_DIR/compressed.pdf"
    
    # Compress
    if ! compress_pdf "$input_file" "medium" "$(dirname $output_file)"; then
        echo "FAILED: Compression failed"
        return 1
    fi
    
    # Verify output exists
    assert_file_exists "$output_file"
    
    # Verify output is smaller
    local input_size=$(stat -c%s "$input_file")
    local output_size=$(stat -c%s "$output_file")
    
    if [ $output_size -ge $input_size ]; then
        echo "FAILED: Output is not smaller than input"
        return 1
    fi
    
    return 0
}

test_compression_quality_levels() {
    local input_file="$TEST_DIR/test.pdf"
    local qualities=("low" "medium" "high")
    
    for quality in "${qualities[@]}"; do
        local output="$TEST_DIR/compressed_${quality}.pdf"
        
        if ! compress_pdf "$input_file" "$quality" "$(dirname $output)"; then
            echo "FAILED: Compression with quality '$quality' failed"
            return 1
        fi
        
        assert_file_exists "$output"
    done
    
    return 0
}

test_batch_compression() {
    # Create multiple test files
    for i in {1..5}; do
        ./tests/create_test_pdf.sh "$TEST_DIR/test_${i}.pdf"
    done
    
    # Compress all
    if ! compress_directory "$TEST_DIR" "medium"; then
        echo "FAILED: Batch compression failed"
        return 1
    fi
    
    # Verify all outputs exist
    for i in {1..5}; do
        local output="$TEST_DIR/test_${i}_compressed.pdf"
        assert_file_exists "$output"
    done
    
    return 0
}

# Run integration tests
describe "Compression Integration Tests"
init_tests

setup_integration
it "compresses PDF file" test_basic_compression
teardown_integration

setup_integration
it "handles all quality levels" test_compression_quality_levels
teardown_integration

setup_integration
it "performs batch compression" test_batch_compression
teardown_integration

print_summary
```

## Edge Case Testing

### Testing Error Conditions

```bash
#!/bin/bash
# tests/test_edge_cases.sh

source ./tests/test_framework.sh
source ./lib/compress.sh

describe "Edge Cases"

test_nonexistent_file() {
    if compress_pdf "/nonexistent/file.pdf" "medium" "."; then
        echo "FAILED: Should have failed for nonexistent file"
        return 1
    fi
    
    # Check correct error code
    [ $? -eq ${ERROR_CODES[FILE_NOT_FOUND]} ]
}

test_invalid_quality() {
    local temp_file=$(mktemp)
    
    if compress_pdf "$temp_file" "invalid_quality" "."; then
        rm -f "$temp_file"
        echo "FAILED: Should have failed for invalid quality"
        return 1
    fi
    
    rm -f "$temp_file"
    return 0
}

test_permission_denied() {
    local test_file=$(mktemp)
    chmod 000 "$test_file"
    
    if compress_pdf "$test_file" "medium" "."; then
        chmod 644 "$test_file"
        rm -f "$test_file"
        echo "FAILED: Should have failed for permission denied"
        return 1
    fi
    
    chmod 644 "$test_file"
    rm -f "$test_file"
    return 0
}

test_zero_byte_file() {
    local test_file=$(mktemp)
    
    # Create zero-byte file
    : > "$test_file"
    
    # Should handle gracefully
    compress_pdf "$test_file" "medium" "."
    local result=$?
    
    rm -f "$test_file"
    
    # Should return appropriate error
    [ $result -ne 0 ]
}

test_very_large_file() {
    # Skip if not enough space
    local available=$(df . | tail -1 | awk '{print $4}')
    [ $available -lt 1000000 ] && return 0
    
    local test_file="tests/output/large_file_$$.pdf"
    
    # Create large file (100MB)
    dd if=/dev/zero of="$test_file" bs=1M count=100 2>/dev/null
    
    # Should handle without crashing
    compress_pdf "$test_file" "low" "."
    local result=$?
    
    rm -f "$test_file"
    
    return 0
}

# Run edge case tests
init_tests
it "handles nonexistent file" test_nonexistent_file
it "rejects invalid quality level" test_invalid_quality
it "handles permission denied" test_permission_denied
it "handles zero-byte file" test_zero_byte_file
it "handles very large file" test_very_large_file
print_summary
```

## Mock and Stub Patterns

### Mocking External Commands

```bash
# Create mock command
mock_gs() {
    # Save original command
    if [ -z "$GS_ORIGINAL" ]; then
        GS_ORIGINAL=$(command -v gs)
    fi
    
    # Create mock
    cat > "tests/output/gs" << 'EOF'
#!/bin/bash
echo "Mock GhostScript called with: $*"
exit 0
EOF
    chmod +x "tests/output/gs"
    
    # Override PATH
    export PATH="tests/output:$PATH"
}

# Restore original command
restore_gs() {
    export PATH="${PATH#tests/output:}"
}

# Test with mock
test_with_mock() {
    mock_gs
    
    # Run function that uses gs
    compress_pdf "test.pdf" "medium" "."
    
    restore_gs
    
    return 0
}
```

### Stubbing Functions

```bash
# Stub a function temporarily
stub_function() {
    local func_name="$1"
    local stub_return="$2"
    
    eval "${func_name}_original() $(declare -f $func_name | tail -n +2)"
    
    eval "${func_name}() { return $stub_return; }"
}

# Restore function
restore_function() {
    local func_name="$1"
    
    eval "${func_name}() $(declare -f ${func_name}_original | tail -n +2)"
    unset -f ${func_name}_original
}

# Usage
test_with_stub() {
    stub_function "check_license" 0
    
    # Test code that calls check_license
    feature_ultra_compression
    local result=$?
    
    restore_function "check_license"
    
    assert_equals 0 $result
}
```

## Continuous Integration

### Test Runner Script

```bash
#!/bin/bash
# run_tests.sh - Main test runner

set -e

echo "CompressKit Test Suite"
echo "======================"
echo

# Track overall result
OVERALL_RESULT=0

# Run test suites
run_suite() {
    local suite="$1"
    echo "Running $suite..."
    
    if bash "$suite"; then
        echo "✓ $suite passed"
    else
        echo "✗ $suite failed"
        OVERALL_RESULT=1
    fi
    echo
}

# Run all test suites
run_suite "tests/test_security.sh"
run_suite "tests/test_security_module.sh"
run_suite "tests/test_compression.sh"
run_suite "tests/test_edge_cases.sh"
run_suite "tests/test_file_operations.sh"

# Summary
echo "======================"
if [ $OVERALL_RESULT -eq 0 ]; then
    echo "✓ All test suites passed!"
    exit 0
else
    echo "✗ Some test suites failed"
    exit 1
fi
```

## Performance Testing

### Measuring Execution Time

```bash
test_performance() {
    local iterations=100
    local start_time=$(date +%s%N)
    
    for ((i=0; i<iterations; i++)); do
        safe_path "/tmp/test.txt" >/dev/null
    done
    
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to ms
    local per_call=$((duration / iterations))
    
    echo "Performance: $per_call ms per call"
    
    # Assert performance threshold
    if [ $per_call -gt 10 ]; then
        echo "FAILED: Performance too slow ($per_call ms > 10 ms)"
        return 1
    fi
    
    return 0
}
```

## Best Practices

### Do's

✅ **Write tests first** (TDD) for new features  
✅ **Test security functions thoroughly** with attack vectors  
✅ **Use descriptive test names** that explain what's being tested  
✅ **Keep tests independent** from each other  
✅ **Clean up test artifacts** in teardown functions  
✅ **Test both success and failure paths**  
✅ **Mock external dependencies** to make tests reliable  
✅ **Run tests in CI/CD** on every commit  
✅ **Measure test coverage** and aim for >80%  

### Don'ts

❌ **Don't skip cleanup** after tests  
❌ **Don't rely on specific system state** (time, locale, etc.)  
❌ **Don't test implementation details**, test behavior  
❌ **Don't make tests dependent** on test order  
❌ **Don't ignore flaky tests**, fix them  
❌ **Don't test library code**, test your code  
❌ **Don't commit commented-out tests**  

## Conclusion

Comprehensive testing transforms shell scripts from fragile utilities into reliable, maintainable applications. CompressKit's test suite demonstrates that systematic testing for Bash scripts is not only possible but essential for production quality.

The key principles are:
1. **Test at multiple levels**: Unit, integration, and system
2. **Focus on security**: Extra scrutiny for security-critical code
3. **Cover edge cases**: Especially error conditions
4. **Automate everything**: CI/CD integration
5. **Keep tests maintainable**: Clear structure and good practices

By implementing these testing strategies, you can build shell scripts with confidence, catch bugs early, and maintain quality as your codebase evolves.

Remember: **Untested code is broken code—you just don't know it yet.**

---

**Resources:**
- [CompressKit Test Suite](https://github.com/CrisisCore-Systems/CompressKit/tree/main/tests)
- [Test Framework](https://github.com/CrisisCore-Systems/CompressKit/blob/main/tests/test_framework.sh)
- [Security Tests](https://github.com/CrisisCore-Systems/CompressKit/blob/main/tests/test_security.sh)

**About the Author:**  
CrisisCore-Systems advocates for quality through comprehensive testing in all software projects.
