#!/bin/bash
# Integration tests for Makefile prerequisites check

set -e

# Source test helpers
source "$(dirname "$0")/../test-helpers.sh"

# Setup
setup_test_env
start_test_suite "Makefile Prerequisites Check"

# Test: Prerequisites pass with all requirements
run_test "Prerequisites pass with all requirements" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"
  copy_test_config "config-minimal.json"

  # Copy templates
  cp -r "$(pwd)/templates" "$TMP_TEST_DIR/"

  # Run check-prereqs
  output=$(make -f "$(pwd)/Makefile" check-prereqs 2>&1)
  exit_code=$?

  assert_exit_code 0 $exit_code "Should pass all checks"
  assert_contains "$output" "✅ All prerequisites met" "Should show success"
'

# Test: Prerequisites fail without .env
run_test "Prerequisites fail without .env" bash -c '
  cd "$TMP_TEST_DIR"
  copy_test_config "config-minimal.json"

  output=$(make -f "$(pwd)/Makefile" check-prereqs 2>&1)
  exit_code=$?

  assert_exit_code 1 $exit_code "Should fail without .env"
  assert_contains "$output" ".env file not found" "Should report missing .env"
'

# Test: Prerequisites fail without config
run_test "Prerequisites fail without config" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"

  output=$(make -f "$(pwd)/Makefile" check-prereqs 2>&1)
  exit_code=$?

  assert_exit_code 1 $exit_code "Should fail without config"
  assert_contains "$output" "project-config.json not found" "Should report missing config"
'

# Test: Prerequisites fail without templates
run_test "Prerequisites fail without templates" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"
  copy_test_config "config-minimal.json"

  output=$(make -f "$(pwd)/Makefile" check-prereqs 2>&1)
  exit_code=$?

  assert_exit_code 1 $exit_code "Should fail without templates"
  assert_contains "$output" "not found" "Should report missing template"
'

# Cleanup
cleanup_test_env
end_test_suite
exit $?
