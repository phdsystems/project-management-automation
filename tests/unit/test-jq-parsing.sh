#!/bin/bash
# Unit tests for jq JSON parsing

set -e

# Source test helpers
source "$(dirname "$0")/../test-helpers.sh"

# Setup
setup_test_env
start_test_suite "JQ JSON Parsing"

# Test: Parse teams from minimal config
run_test "Parse teams from minimal config" bash -c '
  output=$(jq -r ".teams[]" "$FIXTURES_DIR/config-minimal.json")
  assert_contains "$output" "test-team" "Should extract team name"
'

# Test: Parse teams from full config
run_test "Parse teams from full config" bash -c '
  output=$(jq -r ".teams[]" "$FIXTURES_DIR/config-full.json")
  assert_contains "$output" "frontend-team" "Should extract frontend-team"
  assert_contains "$output" "backend-team" "Should extract backend-team"
  assert_contains "$output" "infra-team" "Should extract infra-team"
'

# Test: Count projects
run_test "Count projects" bash -c '
  count=$(jq ".projects | length" "$FIXTURES_DIR/config-full.json")
  assert_equals "2" "$count" "Should have 2 projects"
'

# Test: Extract project names
run_test "Extract project names" bash -c '
  output=$(jq -r ".projects[].name" "$FIXTURES_DIR/config-full.json")
  assert_contains "$output" "alpha" "Should contain alpha"
  assert_contains "$output" "beta" "Should contain beta"
'

# Test: Extract repo details
run_test "Extract repo details" bash -c '
  name=$(jq -r ".projects[0].repos[0].name" "$FIXTURES_DIR/config-minimal.json")
  team=$(jq -r ".projects[0].repos[0].team" "$FIXTURES_DIR/config-minimal.json")
  perm=$(jq -r ".projects[0].repos[0].permission" "$FIXTURES_DIR/config-minimal.json")

  assert_equals "frontend" "$name" "Should extract repo name"
  assert_equals "test-team" "$team" "Should extract team"
  assert_equals "push" "$perm" "Should extract permission"
'

# Test: Invalid JSON handling
run_test "Invalid JSON handling" bash -c '
  output=$(jq "." "$FIXTURES_DIR/config-invalid.json" 2>&1)
  exit_code=$?
  assert_exit_code 4 $exit_code "Should fail on invalid JSON"
'

# Test: Filter repos by role
run_test "Filter repos by role" bash -c '
  output=$(jq -r ".projects[].repos[] | select(.name == \"frontend\") | .team" "$FIXTURES_DIR/config-full.json")
  assert_contains "$output" "frontend-team" "Should find frontend repos"
'

# Cleanup
cleanup_test_env
end_test_suite
exit $?
