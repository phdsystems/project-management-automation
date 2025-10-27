#!/bin/bash
# Integration tests for Makefile repos target

set -e

# Source test helpers
source "$(dirname "$0")/../test-helpers.sh"

# Setup
setup_test_env
start_test_suite "Makefile Repos Target"

# Test: Create repository with correct naming
run_test "Create repository with correct naming" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"
  copy_test_config "config-minimal.json"
  cp -r "$(pwd)/templates" "$TMP_TEST_DIR/"

  export TEST_ACCOUNT_TYPE="Organization"

  output=$(make -f "$(pwd)/Makefile" repos DRY_RUN=1 2>&1)

  assert_contains "$output" "project-minimal-frontend" "Should use correct naming pattern"
'

# Test: Create multiple repos for multiple projects
run_test "Create multiple repos for multiple projects" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"
  copy_test_config "config-full.json"
  cp -r "$(pwd)/templates" "$TMP_TEST_DIR/"

  export TEST_ACCOUNT_TYPE="Organization"

  output=$(make -f "$(pwd)/Makefile" repos DRY_RUN=1 2>&1)

  # Project alpha
  assert_contains "$output" "project-alpha-frontend" "Should create alpha frontend"
  assert_contains "$output" "project-alpha-backend" "Should create alpha backend"
  assert_contains "$output" "project-alpha-infra" "Should create alpha infra"

  # Project beta
  assert_contains "$output" "project-beta-frontend" "Should create beta frontend"
  assert_contains "$output" "project-beta-backend" "Should create beta backend"
'

# Test: Assign teams with correct permissions
run_test "Assign teams with correct permissions" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"
  copy_test_config "config-full.json"
  cp -r "$(pwd)/templates" "$TMP_TEST_DIR/"

  export TEST_ACCOUNT_TYPE="Organization"

  output=$(make -f "$(pwd)/Makefile" repos DRY_RUN=1 2>&1)

  assert_contains "$output" "frontend-team.*push" "Should assign frontend-team with push"
  assert_contains "$output" "infra-team.*admin" "Should assign infra-team with admin"
'

# Cleanup
cleanup_test_env
end_test_suite
exit $?
