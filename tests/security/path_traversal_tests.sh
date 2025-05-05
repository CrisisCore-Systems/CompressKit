#!/data/data/com.termux/files/usr/bin/bash

# Path traversal security tests for CompressKit

# Import main framework if running directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/security_test_framework.sh"
fi

# Import libraries to test
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${ROOT_DIR}/lib/secure_utils.sh"

# Test safe_path function with normal paths
test_path_traversal_safe_path_normal() {
    local result
    result=$(safe_path "/tmp/test.txt")
    
    # Test should pass if path is returned unchanged
    [[ "$result" == "/tmp/test.txt" ]]
}

# Test safe_path function with traversal attempt
test_path_traversal_safe_path_attack() {
    local result
    result=$(safe_path "../../../etc/passwd")
    
    # Test should pass if function rejects the path (empty result)
    [[ -z "$result" ]]
}

# Test safe_path function with encoded traversal
test_path_traversal_safe_path_encoded() {
    local result
    result=$(safe_path "%2e%2e/%2e%2e/etc/passwd")
    
    # Test should pass if function rejects the path (empty result)
    [[ -z "$result" ]]
}

# Test file operations with traversal attempt
test_path_traversal_file_operations() {
    # Create a temporary test function that uses safe_path
    test_file_op() {
        local path="$1"
        local safe_file
        
        safe_file=$(safe_path "$path")
        if [ $? -ne 0 ] || [ -z "$safe_file" ]; then
            return 1
        fi
        
        # Try to access the file (should fail for invalid paths)
        if [ -f "$safe_file" ]; then
            return 0
        fi
        return 1
    }
    
    # Try with a traversal attack
    ! test_file_op "../../../etc/passwd"
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_security_test "safe_path normal paths" "path_traversal" test_path_traversal_safe_path_normal
    run_security_test "safe_path with traversal" "path_traversal" test_path_traversal_safe_path_attack
    run_security_test "safe_path with encoded traversal" "path_traversal" test_path_traversal_safe_path_encoded
    run_security_test "file operations with traversal" "path_traversal" test_path_traversal_file_operations
fi
