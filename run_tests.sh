#!/data/data/com.termux/files/usr/bin/bash

# Test runner for CompressKit

# Set up test environment
export TEST_MODE=1
export TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

# Run all tests
echo -e "${BLUE}Running main test suite...${NC}"
bash tests/test_suite.sh
MAIN_TESTS_RESULT=$?

echo -e "${BLUE}Running security tests...${NC}"
bash tests/test_security.sh
SECURITY_TESTS_RESULT=$?

echo -e "${BLUE}Running security module tests...${NC}"
bash tests/test_security_module.sh
SECURITY_MODULE_TESTS_RESULT=$?

echo -e "${BLUE}Running edge case tests...${NC}"
bash tests/test_edge_cases.sh
EDGE_CASE_TESTS_RESULT=$?

echo -e "${BLUE}Running compression tests...${NC}"
bash tests/test_compression.sh
COMPRESSION_TESTS_RESULT=$?

# Print overall results
echo -e "\n${BLUE}Test Suite Results:${NC}"
echo "======================================"
echo -e "Main tests: $([ $MAIN_TESTS_RESULT -eq 0 ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${RED}FAILED${NC}")"
echo -e "Security tests: $([ $SECURITY_TESTS_RESULT -eq 0 ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${RED}FAILED${NC}")"
echo -e "Security module tests: $([ $SECURITY_MODULE_TESTS_RESULT -eq 0 ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${RED}FAILED${NC}")"
echo -e "Edge case tests: $([ $EDGE_CASE_TESTS_RESULT -eq 0 ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${RED}FAILED${NC}")"
echo -e "Compression tests: $([ $COMPRESSION_TESTS_RESULT -eq 0 ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${RED}FAILED${NC}")"
echo "======================================"

# Exit with combined test result
if [ $MAIN_TESTS_RESULT -eq 0 ] && [ $SECURITY_TESTS_RESULT -eq 0 ] && [ $SECURITY_MODULE_TESTS_RESULT -eq 0 ] && [ $EDGE_CASE_TESTS_RESULT -eq 0 ] && [ $COMPRESSION_TESTS_RESULT -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
