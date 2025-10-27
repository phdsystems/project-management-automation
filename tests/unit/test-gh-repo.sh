#!/bin/bash
# Unit tests for gh repo commands

set -e

# Source test helpers
source "$(dirname "$0")/../test-helpers.sh"

# Setup
setup_test_env
start_test_suite "GH Repo Commands"

# Test: Create repository
run_test "Create repository" bash -c '
  output=$(gh repo create test-org/test-repo --private 2>&1)
  exit_code=$?
  assert_exit_code 0 $exit_code "Should succeed"
  assert_contains "$output" "https://github.com/test-org/test-repo" "Should return repo URL"
  assert_command_called "repo create" "Should call repo create"
'

# Test: Create repository without name fails
run_test "Create repository without name fails" bash -c '
  output=$(gh repo create --private 2>&1)
  exit_code=$?
  assert_exit_code 1 $exit_code "Should fail"
  assert_contains "$output" "repository name required" "Should require name"
'

# Test: View existing repository
run_test "View existing repository" bash -c '
  export MOCK_REPO_EXISTS="true"
  output=$(gh repo view test-org/test-repo --json name,visibility,createdAt 2>&1)
  exit_code=$?
  assert_exit_code 0 $exit_code "Should succeed"
  assert_contains "$output" "test-repo" "Should contain repo name"
  assert_contains "$output" "PRIVATE" "Should show visibility"
'

# Test: View nonexistent repository
run_test "View nonexistent repository" bash -c '
  export MOCK_REPO_EXISTS="false"
  output=$(gh repo view test-org/nonexistent --json name 2>&1)
  exit_code=$?
  assert_exit_code 1 $exit_code "Should fail"
  assert_contains "$output" "not found" "Should return not found"
'

# Test: Delete repository
run_test "Delete repository" bash -c '
  output=$(gh repo delete test-org/test-repo --yes 2>&1)
  exit_code=$?
  assert_exit_code 0 $exit_code "Should succeed"
  assert_command_called "repo delete" "Should call repo delete"
'

# Cleanup
cleanup_test_env
end_test_suite
exit $?
