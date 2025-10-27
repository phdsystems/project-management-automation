#!/bin/bash
# Unit tests for gh auth commands

# Source test helpers
source "$(dirname "$0")/../test-helpers.sh"

# Setup
setup_test_env
start_test_suite "GH Auth Commands"

# Test: gh auth status returns success
test_gh_auth_status_success() {
  local output exit_code
  output=$(gh auth status 2>&1)
  exit_code=$?
  assert_exit_code 0 $exit_code "Should exit with 0" || return 1
  assert_contains "$output" "Logged in" "Should contain login status" || return 1
  return 0
}
run_test "gh auth status returns success" test_gh_auth_status_success

# Test: gh auth status shows correct format
test_gh_auth_status_format() {
  local output
  output=$(gh auth status 2>&1)
  assert_contains "$output" "github.com" "Should contain github.com" || return 1
  assert_contains "$output" "Token scopes" "Should contain token scopes" || return 1
  return 0
}
run_test "gh auth status shows correct format" test_gh_auth_status_format

# Cleanup
cleanup_test_env
end_test_suite
exit $?
