#!/data/data/com.termux/files/usr/bin/bash

# Test runner for CompressKit

# Set up test environment
export TEST_MODE=1
export TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run all tests
bash tests/test_suite.sh

# Exit with test suite exit code
exit $?
