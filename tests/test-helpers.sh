#!/bin/bash
# Test Helper Functions
# Source this file in test scripts: source tests/test-helpers.sh

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test environment
setup_test_env() {
  export TEST_DIR="$(pwd)/tests"
  export FIXTURES_DIR="$TEST_DIR/fixtures"
  export MOCKS_DIR="$TEST_DIR/mocks"
  export TMP_TEST_DIR="/tmp/gh-automation-tests-$$"

  # Create temp directory
  mkdir -p "$TMP_TEST_DIR"

  # Prepend mocks to PATH
  export PATH="$MOCKS_DIR:$PATH"

  # Set up mock log
  export MOCK_LOG="$TMP_TEST_DIR/mock-calls.log"
  > "$MOCK_LOG"

  # Default test environment variables
  export TEST_ACCOUNT_TYPE="${TEST_ACCOUNT_TYPE:-Organization}"
  export MOCK_TEAM_EXISTS="${MOCK_TEAM_EXISTS:-false}"
  export MOCK_REPO_EXISTS="${MOCK_REPO_EXISTS:-false}"
}

# Cleanup test environment
cleanup_test_env() {
  if [[ -d "$TMP_TEST_DIR" ]]; then
    rm -rf "$TMP_TEST_DIR"
  fi
}

# Create test .env file
create_test_env_file() {
  local org="${1:-test-org}"
  cat > "$TMP_TEST_DIR/.env" <<EOF
ORG=$org
CONFIG=project-config.json
DEFAULT_BRANCH=main
DRY_RUN=0
VERBOSE=0
EOF
}

# Copy test config
copy_test_config() {
  local config_name="$1"
  cp "$FIXTURES_DIR/$config_name" "$TMP_TEST_DIR/project-config.json"
}

# Assert helpers
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Assertion failed}"

  ((TESTS_RUN++))

  if [[ "$expected" == "$actual" ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} $message"
    echo -e "  Expected: $expected"
    echo -e "  Actual:   $actual"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Assertion failed}"

  ((TESTS_RUN++))

  if [[ "$haystack" == *"$needle"* ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} $message"
    echo -e "  Expected to contain: $needle"
    echo -e "  In: $haystack"
    return 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Assertion failed}"

  ((TESTS_RUN++))

  if [[ "$haystack" != *"$needle"* ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} $message"
    echo -e "  Expected NOT to contain: $needle"
    echo -e "  In: $haystack"
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist: $file}"

  ((TESTS_RUN++))

  if [[ -f "$file" ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} $message"
    return 1
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Exit code should be $expected}"

  ((TESTS_RUN++))

  if [[ "$expected" -eq "$actual" ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} $message"
    echo -e "  Expected: $expected"
    echo -e "  Actual:   $actual"
    return 1
  fi
}

assert_command_called() {
  local command="$1"
  local message="${2:-Command should be called: $command}"

  ((TESTS_RUN++))

  if grep -q "$command" "$MOCK_LOG" 2>/dev/null; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} $message"
    echo -e "  Mock log contents:"
    cat "$MOCK_LOG" | sed 's/^/    /'
    return 1
  fi
}

# Test suite helpers
start_test_suite() {
  local suite_name="$1"
  echo ""
  echo -e "${BLUE}════════════════════════════════════════${NC}"
  echo -e "${BLUE}  Test Suite: $suite_name${NC}"
  echo -e "${BLUE}════════════════════════════════════════${NC}"
  echo ""

  TESTS_RUN=0
  TESTS_PASSED=0
  TESTS_FAILED=0
}

end_test_suite() {
  echo ""
  echo -e "${BLUE}────────────────────────────────────────${NC}"
  echo -e "  Tests run:    $TESTS_RUN"
  echo -e "  ${GREEN}Tests passed: $TESTS_PASSED${NC}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "  ${RED}Tests failed: $TESTS_FAILED${NC}"
  else
    echo -e "  Tests failed: 0"
  fi
  echo -e "${BLUE}────────────────────────────────────────${NC}"
  echo ""

  return $TESTS_FAILED
}

# Run a test with description
run_test() {
  local test_name="$1"
  shift

  echo -e "${YELLOW}Test:${NC} $test_name"
  "$@"
  echo ""
}

# Mock command response
mock_command() {
  local command="$1"
  local response="$2"

  # Create mock script
  cat > "$MOCKS_DIR/$command" <<EOF
#!/bin/bash
echo "$response"
exit 0
EOF
  chmod +x "$MOCKS_DIR/$command"
}
