#!/bin/bash
# Main test runner for GitHub Organization Automation
# Runs unit, integration, and end-to-end tests

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
UNIT_DIR="$SCRIPT_DIR/unit"
INTEGRATION_DIR="$SCRIPT_DIR/integration"
E2E_DIR="$SCRIPT_DIR/e2e"

# Test counters
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Parse command line arguments
TEST_TYPE="${1:-all}"  # all, unit, integration, e2e
VERBOSE="${VERBOSE:-0}"

# Display usage
usage() {
  cat <<EOF
Usage: $0 [test-type] [options]

Test Types:
  all          Run all tests (default)
  unit         Run unit tests only
  integration  Run integration tests only
  e2e          Run end-to-end tests only

Environment Variables:
  VERBOSE=1    Enable verbose output

Examples:
  $0                    # Run all tests
  $0 unit               # Run unit tests only
  VERBOSE=1 $0          # Run all tests with verbose output
  $0 integration        # Run integration tests only

EOF
  exit 1
}

# Handle help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
fi

# Print test header
print_header() {
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║                                                        ║${NC}"
  echo -e "${CYAN}║  GitHub Organization Automation - Test Suite          ║${NC}"
  echo -e "${CYAN}║                                                        ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# Print test category header
print_category() {
  local category="$1"
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  $category${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# Run test suite
run_test_suite() {
  local test_file="$1"
  local test_name="$(basename "$test_file" .sh)"

  echo -e "${YELLOW}Running:${NC} $test_name"

  ((TOTAL_SUITES++))

  if [[ "$VERBOSE" == "1" ]]; then
    if bash "$test_file"; then
      ((PASSED_SUITES++))
      echo -e "${GREEN}✓ PASSED:${NC} $test_name"
    else
      ((FAILED_SUITES++))
      echo -e "${RED}✗ FAILED:${NC} $test_name"
    fi
  else
    # Capture output
    if output=$(bash "$test_file" 2>&1); then
      ((PASSED_SUITES++))
      echo -e "${GREEN}✓ PASSED:${NC} $test_name"
    else
      ((FAILED_SUITES++))
      echo -e "${RED}✗ FAILED:${NC} $test_name"
      echo "$output"
    fi
  fi

  echo ""
}

# Run all tests in a directory
run_test_category() {
  local category="$1"
  local test_dir="$2"

  if [[ ! -d "$test_dir" ]]; then
    echo -e "${YELLOW}Warning:${NC} Test directory not found: $test_dir"
    return
  fi

  local test_count=$(find "$test_dir" -name "test-*.sh" -type f | wc -l)
  if [[ "$test_count" -eq 0 ]]; then
    echo -e "${YELLOW}No tests found in:${NC} $test_dir"
    return
  fi

  print_category "$category"

  for test_file in "$test_dir"/test-*.sh; do
    if [[ -f "$test_file" ]]; then
      run_test_suite "$test_file"
    fi
  done
}

# Print summary
print_summary() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  Test Summary${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "  Total Suites:  $TOTAL_SUITES"
  echo -e "  ${GREEN}Passed:        $PASSED_SUITES${NC}"

  if [[ $FAILED_SUITES -gt 0 ]]; then
    echo -e "  ${RED}Failed:        $FAILED_SUITES${NC}"
  else
    echo "  Failed:        0"
  fi

  echo ""

  if [[ $FAILED_SUITES -eq 0 ]]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                        ║${NC}"
    echo -e "${GREEN}║  ✓ ALL TESTS PASSED                                   ║${NC}"
    echo -e "${GREEN}║                                                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
  else
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                        ║${NC}"
    echo -e "${RED}║  ✗ SOME TESTS FAILED                                  ║${NC}"
    echo -e "${RED}║                                                        ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
  fi

  echo ""
}

# Main execution
main() {
  # Change to project root
  cd "$PROJECT_ROOT"

  print_header

  case "$TEST_TYPE" in
    unit)
      run_test_category "Unit Tests" "$UNIT_DIR"
      ;;
    integration)
      run_test_category "Integration Tests" "$INTEGRATION_DIR"
      ;;
    e2e)
      run_test_category "End-to-End Tests" "$E2E_DIR"
      ;;
    all)
      run_test_category "Unit Tests" "$UNIT_DIR"
      run_test_category "Integration Tests" "$INTEGRATION_DIR"
      run_test_category "End-to-End Tests" "$E2E_DIR"
      ;;
    *)
      echo -e "${RED}Error:${NC} Unknown test type: $TEST_TYPE"
      usage
      ;;
  esac

  print_summary

  # Exit with failure code if any tests failed
  exit $FAILED_SUITES
}

# Run main
main
