#!/data/data/com.termux/files/usr/bin/bash

# Import test framework
source "tests/test_framework.sh"

# Load system components
source "lib/secure_utils.sh"

# Initialize test environment
init_tests

describe "Path Validation Edge Cases"

it "should reject paths containing Unicode RTL markers" && {
    # Right-to-left override character U+202E can be used to spoof file extensions
    local path="malicious$(echo -e '\u202E')fdp.txt"
    safe_path "$path" > /dev/null
    assert_equals 1 $?
}

it "should handle very long paths correctly" && {
    local long_path=$(printf '/tmp/%0255d' 1)
    local result=$(safe_path "$long_path")
    assert_equals 0 $?
    assert_equals $long_path "$result"
}

# Run all tests
print_test_results
