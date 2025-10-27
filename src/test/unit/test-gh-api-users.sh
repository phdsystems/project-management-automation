#!/bin/bash
# Unit tests for gh api users commands

set -e

# Source test helpers
source "$(dirname "$0")/../test-helpers.sh"

# Setup
setup_test_env
start_test_suite "GH API Users Commands"

# Test: Check account type (Organization)
run_test "Check account type (Organization)" bash -c '
  export TEST_ACCOUNT_TYPE="Organization"
  output=$(gh api /users/test-org 2>&1)
  exit_code=$?
  assert_exit_code 0 $exit_code "Should succeed"
  assert_contains "$output" "\"type\": \"Organization\"" "Should be Organization type"
'

# Test: Check account type (User)
run_test "Check account type (User)" bash -c '
  export TEST_ACCOUNT_TYPE="User"
  output=$(gh api /users/test-user 2>&1)
  exit_code=$?
  assert_exit_code 0 $exit_code "Should succeed"
  assert_contains "$output" "\"type\": \"User\"" "Should be User type"
'

# Test: Get user organizations (User account)
run_test "Get user organizations (User account)" bash -c '
  export TEST_ACCOUNT_TYPE="User"
  output=$(gh api /user/orgs 2>&1)
  exit_code=$?
  assert_exit_code 0 $exit_code "Should succeed"
  assert_equals "[]" "$output" "Should return empty array"
'

# Test: Get user organizations (Org member)
run_test "Get user organizations (Org member)" bash -c '
  export TEST_ACCOUNT_TYPE="Organization"
  output=$(gh api /user/orgs 2>&1)
  exit_code=$?
  assert_exit_code 0 $exit_code "Should succeed"
  assert_contains "$output" "test-org" "Should contain org"
'

# Cleanup
cleanup_test_env
end_test_suite
exit $?
