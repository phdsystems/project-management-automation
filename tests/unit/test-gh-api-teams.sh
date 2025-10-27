#!/bin/bash
# Unit tests for gh api teams commands

set -e

# Source test helpers
source "$(dirname "$0")/../test-helpers.sh"

# Setup
setup_test_env
start_test_suite "GH API Teams Commands"

# Test: List teams on organization account
run_test "List teams on organization account" bash -c '
  export TEST_ACCOUNT_TYPE="Organization"
  output=$(gh api /orgs/test-org/teams 2>&1)
  exit_code=$?
  assert_exit_code 0 $exit_code "Should succeed for organization"
  assert_contains "$output" "test-team" "Should list teams"
'

# Test: List teams on user account fails
run_test "List teams on user account fails" bash -c '
  export TEST_ACCOUNT_TYPE="User"
  output=$(gh api /orgs/test-user/teams 2>&1)
  exit_code=$?
  assert_exit_code 1 $exit_code "Should fail for user account"
  assert_contains "$output" "Not Found" "Should return 404"
'

# Test: Get specific team (exists)
run_test "Get specific team (exists)" bash -c '
  export TEST_ACCOUNT_TYPE="Organization"
  export MOCK_TEAM_EXISTS="true"
  output=$(gh api /orgs/test-org/teams/test-team 2>&1)
  exit_code=$?
  assert_exit_code 0 $exit_code "Should find existing team"
  assert_contains "$output" "test-team" "Should contain team name"
'

# Test: Get specific team (not found)
run_test "Get specific team (not found)" bash -c '
  export TEST_ACCOUNT_TYPE="Organization"
  export MOCK_TEAM_EXISTS="false"
  output=$(gh api /orgs/test-org/teams/nonexistent 2>&1)
  exit_code=$?
  assert_exit_code 1 $exit_code "Should fail for nonexistent team"
  assert_contains "$output" "Not Found" "Should return 404"
'

# Test: Check team on user account fails
run_test "Check team on user account fails" bash -c '
  export TEST_ACCOUNT_TYPE="User"
  output=$(gh api /orgs/test-user/teams/any-team 2>&1)
  exit_code=$?
  assert_exit_code 1 $exit_code "Should fail for user account"
'

# Cleanup
cleanup_test_env
end_test_suite
exit $?
