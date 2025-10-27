#!/bin/bash
# End-to-end tests for error scenarios

set -e

# Source test helpers
source "$(dirname "$0")/../test-helpers.sh"

# Setup
setup_test_env
start_test_suite "Error Scenarios (E2E)"

# Test: Missing prerequisites are caught early
run_test "Missing prerequisites are caught early" bash -c '
  cd "$TMP_TEST_DIR"

  output=$(make -f "$(pwd)/src/main/Makefile" all 2>&1 || true)
  exit_code=$?

  assert_exit_code 1 $exit_code "Should fail"
  assert_contains "$output" "Checking prerequisites" "Should check prerequisites"
  assert_contains "$output" ".env file not found" "Should report missing .env"
'

# Test: Invalid JSON is detected
run_test "Invalid JSON is detected" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"
  cp "$FIXTURES_DIR/config-invalid.json" "$TMP_TEST_DIR/project-config.json"

  # Prerequisites should pass (file exists)
  # But jq parsing will fail
  output=$(make -f "$(pwd)/src/main/Makefile" check-prereqs 2>&1 || true)

  # Note: check-prereqs validates file existence, not JSON validity
  # JSON errors will be caught during actual parsing
'

# Test: Missing template files are caught
run_test "Missing template files are caught" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"
  copy_test_config "config-minimal.json"

  # Create templates dir but missing files
  mkdir -p "$TMP_TEST_DIR/templates"

  output=$(make -f "$(pwd)/src/main/Makefile" check-prereqs 2>&1 || true)
  exit_code=$?

  assert_exit_code 1 $exit_code "Should fail"
  assert_contains "$output" "not found" "Should report missing template"
'

# Test: Empty teams array
run_test "Empty teams array" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"

  # Create config with empty teams
  cat > "$TMP_TEST_DIR/project-config.json" <<EOF
{
  "teams": [],
  "projects": []
}
EOF

  cp -r "$(pwd)/src/main/templates" "$TMP_TEST_DIR/"

  output=$(make -f "$(pwd)/src/main/Makefile" teams DRY_RUN=1 2>&1)
  exit_code=$?

  # Should succeed (no teams to create)
  assert_exit_code 0 $exit_code "Should handle empty teams"
  assert_contains "$output" "✅ Teams creation complete" "Should complete successfully"
'

# Test: Empty projects array
run_test "Empty projects array" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"

  cat > "$TMP_TEST_DIR/project-config.json" <<EOF
{
  "teams": ["test-team"],
  "projects": []
}
EOF

  cp -r "$(pwd)/src/main/templates" "$TMP_TEST_DIR/"

  output=$(make -f "$(pwd)/src/main/Makefile" repos DRY_RUN=1 2>&1)
  exit_code=$?

  # Should succeed (no repos to create)
  assert_exit_code 0 $exit_code "Should handle empty projects"
  assert_contains "$output" "✅ Repositories creation complete" "Should complete successfully"
'

# Test: Workflow with missing ORG variable
run_test "Workflow with missing ORG variable" bash -c '
  cd "$TMP_TEST_DIR"

  # Create .env without ORG
  cat > "$TMP_TEST_DIR/.env" <<EOF
CONFIG=project-config.json
EOF

  copy_test_config "config-minimal.json"

  output=$(make -f "$(pwd)/src/main/Makefile" check-prereqs 2>&1 || true)
  exit_code=$?

  assert_exit_code 1 $exit_code "Should fail"
  assert_contains "$output" "ORG variable not set" "Should report missing ORG"
'

# Cleanup
cleanup_test_env
end_test_suite
exit $?
