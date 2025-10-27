#!/bin/bash
# Integration tests for Makefile teams target

set -e

# Source test helpers
source "$(dirname "$0")/../test-helpers.sh"

# Setup
setup_test_env
start_test_suite "Makefile Teams Target"

# Test: Create teams on organization account
run_test "Create teams on organization account" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"
  copy_test_config "config-minimal.json"
  cp -r "$(pwd)/src/main/templates" "$TMP_TEST_DIR/"

  export TEST_ACCOUNT_TYPE="Organization"
  export MOCK_TEAM_EXISTS="false"

  output=$(make -f "$(pwd)/src/main/Makefile" teams 2>&1)
  exit_code=$?

  assert_exit_code 0 $exit_code "Should succeed"
  assert_contains "$output" "Creating team" "Should create teams"
  assert_contains "$output" "✅ Teams creation complete" "Should complete successfully"
'

# Test: Skip existing teams (idempotent)
run_test "Skip existing teams (idempotent)" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"
  copy_test_config "config-minimal.json"
  cp -r "$(pwd)/src/main/templates" "$TMP_TEST_DIR/"

  export TEST_ACCOUNT_TYPE="Organization"
  export MOCK_TEAM_EXISTS="true"

  output=$(make -f "$(pwd)/src/main/Makefile" teams 2>&1)
  exit_code=$?

  assert_exit_code 0 $exit_code "Should succeed"
  assert_contains "$output" "already exists" "Should skip existing teams"
'

# Test: Multiple teams from full config
run_test "Multiple teams from full config" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"
  copy_test_config "config-full.json"
  cp -r "$(pwd)/src/main/templates" "$TMP_TEST_DIR/"

  export TEST_ACCOUNT_TYPE="Organization"
  export MOCK_TEAM_EXISTS="false"

  output=$(make -f "$(pwd)/src/main/Makefile" teams DRY_RUN=1 2>&1)

  assert_contains "$output" "frontend-team" "Should process frontend-team"
  assert_contains "$output" "backend-team" "Should process backend-team"
  assert_contains "$output" "infra-team" "Should process infra-team"
'

# Cleanup
cleanup_test_env
end_test_suite
exit $?
