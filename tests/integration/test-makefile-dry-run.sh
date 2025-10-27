#!/bin/bash
# Integration tests for Makefile dry-run mode

set -e

# Source test helpers
source "$(dirname "$0")/../test-helpers.sh"

# Setup
setup_test_env
start_test_suite "Makefile Dry-Run Mode"

# Test: Dry-run mode doesn't create resources
run_test "Dry-run mode doesn't create resources" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"
  copy_test_config "config-minimal.json"
  cp -r "$(pwd)/templates" "$TMP_TEST_DIR/"

  export TEST_ACCOUNT_TYPE="Organization"

  # Clear mock log
  > "$MOCK_LOG"

  # Run in dry-run mode
  output=$(make -f "$(pwd)/Makefile" teams DRY_RUN=1 2>&1)
  exit_code=$?

  assert_exit_code 0 $exit_code "Should succeed"
  assert_contains "$output" "[DRY RUN]" "Should show dry-run indicator"
  assert_contains "$output" "Would create team" "Should show what would happen"

  # Verify no actual API calls to create teams
  ! grep -q "api -X POST" "$MOCK_LOG" || {
    echo "ERROR: Dry-run should not make POST requests"
    exit 1
  }
'

# Test: Dry-run shows all planned actions
run_test "Dry-run shows all planned actions" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"
  copy_test_config "config-full.json"
  cp -r "$(pwd)/templates" "$TMP_TEST_DIR/"

  export TEST_ACCOUNT_TYPE="Organization"

  output=$(make -f "$(pwd)/Makefile" all DRY_RUN=1 2>&1)

  assert_contains "$output" "Would create team: frontend-team" "Should show team creation"
  assert_contains "$output" "Would create team: backend-team" "Should show team creation"
  assert_contains "$output" "Would create repo" "Should show repo creation"
  assert_contains "$output" "Would add README" "Should show README addition"
  assert_contains "$output" "Would add workflow" "Should show workflow addition"
'

# Cleanup
cleanup_test_env
end_test_suite
exit $?
