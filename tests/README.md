# Test Suite Documentation

**Version:** 1.0.0
**Last Updated:** 2025-10-27

## Overview

Comprehensive test suite for the GitHub Organization Automation tool, including unit tests, integration tests, and end-to-end tests.

## Quick Start

```bash
# Run all tests
./tests/run-tests.sh

# Run specific test type
./tests/run-tests.sh unit
./tests/run-tests.sh integration
./tests/run-tests.sh e2e

# Run with verbose output
VERBOSE=1 ./tests/run-tests.sh
```

## Test Structure

```
tests/
├── run-tests.sh           # Main test runner
├── test-helpers.sh        # Shared test utilities
├── README.md              # This file
│
├── fixtures/              # Test data
│   ├── config-minimal.json
│   ├── config-full.json
│   └── config-invalid.json
│
├── mocks/                 # Mock implementations
│   └── gh                 # Mock GitHub CLI
│
├── unit/                  # Unit tests
│   ├── test-gh-auth.sh
│   ├── test-gh-api-teams.sh
│   ├── test-gh-api-users.sh
│   ├── test-gh-repo.sh
│   └── test-jq-parsing.sh
│
├── integration/           # Integration tests
│   ├── test-makefile-prereqs.sh
│   ├── test-makefile-dry-run.sh
│   ├── test-makefile-teams.sh
│   └── test-makefile-repos.sh
│
└── e2e/                   # End-to-end tests
    ├── test-full-workflow.sh
    └── test-error-scenarios.sh
```

## Test Types

### Unit Tests

Test individual components in isolation with mocked dependencies.

**Coverage:**
- `gh auth` commands
- `gh api` team endpoints
- `gh api` user endpoints
- `gh repo` operations
- `jq` JSON parsing

**Location:** `tests/unit/`

**Run:**
```bash
./tests/run-tests.sh unit
```

**Example:**
```bash
# Test gh auth status
./tests/unit/test-gh-auth.sh
```

### Integration Tests

Test Makefile targets with mocked GitHub API.

**Coverage:**
- Prerequisites validation
- Dry-run mode
- Team creation workflow
- Repository creation workflow
- Template application

**Location:** `tests/integration/`

**Run:**
```bash
./tests/run-tests.sh integration
```

**Example:**
```bash
# Test prerequisites check
./tests/integration/test-makefile-prereqs.sh
```

### End-to-End Tests

Test complete workflows from start to finish.

**Coverage:**
- Full automation workflow
- Multi-project scenarios
- Idempotency
- Template matching
- Error handling

**Location:** `tests/e2e/`

**Run:**
```bash
./tests/run-tests.sh e2e
```

**Example:**
```bash
# Test full workflow
./tests/e2e/test-full-workflow.sh
```

## Test Fixtures

### config-minimal.json

Minimal valid configuration with one team and one repository.

```json
{
  "teams": ["test-team"],
  "projects": [{
    "name": "minimal",
    "repos": [{
      "name": "frontend",
      "team": "test-team",
      "permission": "push"
    }]
  }]
}
```

### config-full.json

Complete configuration with multiple teams and projects.

- 3 teams (frontend, backend, infra)
- 2 projects (alpha, beta)
- 5 total repositories

### config-invalid.json

Invalid JSON for testing error handling (missing closing brace).

## Mock System

### Mock GitHub CLI (`tests/mocks/gh`)

Simulates GitHub CLI responses without making actual API calls.

**Features:**
- User vs Organization account simulation
- Team existence checks
- Repository operations
- Call logging for verification

**Environment Variables:**
- `TEST_ACCOUNT_TYPE` - Set to "Organization" or "User"
- `MOCK_TEAM_EXISTS` - Set to "true" or "false"
- `MOCK_REPO_EXISTS` - Set to "true" or "false"
- `MOCK_LOG` - Path to call log file

**Example:**
```bash
export TEST_ACCOUNT_TYPE="Organization"
export MOCK_TEAM_EXISTS="true"

# This will return mocked team data
gh api /orgs/test-org/teams/test-team
```

## Test Helpers

Source `test-helpers.sh` in your test scripts:

```bash
source "$(dirname "$0")/../test-helpers.sh"
```

### Setup/Cleanup Functions

```bash
setup_test_env()      # Initialize test environment
cleanup_test_env()    # Clean up temporary files
create_test_env_file() # Create .env file
copy_test_config()    # Copy fixture to test dir
```

### Assertion Functions

```bash
assert_equals expected actual message
assert_contains haystack needle message
assert_not_contains haystack needle message
assert_file_exists file message
assert_exit_code expected actual message
assert_command_called command message
```

### Test Suite Functions

```bash
start_test_suite name  # Begin test suite
end_test_suite         # End suite and return status
run_test name command  # Run individual test
```

## Writing Tests

### Unit Test Template

```bash
#!/bin/bash
set -e

source "$(dirname "$0")/../test-helpers.sh"

setup_test_env
start_test_suite "My Test Suite"

run_test "Test description" bash -c '
  # Test code here
  output=$(command_to_test)
  assert_contains "$output" "expected" "Should contain expected"
'

cleanup_test_env
end_test_suite
exit $?
```

### Integration Test Template

```bash
#!/bin/bash
set -e

source "$(dirname "$0")/../test-helpers.sh"

setup_test_env
start_test_suite "Makefile Integration Test"

run_test "Test Makefile target" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"
  copy_test_config "config-minimal.json"
  cp -r "$(pwd)/templates" "$TMP_TEST_DIR/"

  export TEST_ACCOUNT_TYPE="Organization"

  output=$(make -f "$(pwd)/Makefile" target_name 2>&1)
  assert_exit_code 0 $? "Should succeed"
  assert_contains "$output" "expected" "Should show expected output"
'

cleanup_test_env
end_test_suite
exit $?
```

### E2E Test Template

```bash
#!/bin/bash
set -e

source "$(dirname "$0")/../test-helpers.sh"

setup_test_env
start_test_suite "E2E Test"

run_test "Complete workflow" bash -c '
  cd "$TMP_TEST_DIR"
  create_test_env_file "test-org"
  copy_test_config "config-full.json"
  cp -r "$(pwd)/templates" "$TMP_TEST_DIR/"

  export TEST_ACCOUNT_TYPE="Organization"

  output=$(make -f "$(pwd)/Makefile" all DRY_RUN=1 2>&1)
  assert_exit_code 0 $? "Should complete successfully"

  # Verify all stages
  assert_contains "$output" "Checking prerequisites" "Should check prereqs"
  assert_contains "$output" "Creating teams" "Should create teams"
  # ... more assertions
'

cleanup_test_env
end_test_suite
exit $?
```

## Continuous Integration

Tests run automatically on GitHub Actions:

**Triggers:**
- Push to `main` or `develop`
- Pull requests to `main` or `develop`
- Manual workflow dispatch

**Jobs:**
- Unit tests
- Integration tests
- End-to-end tests
- All tests combined
- Shell script linting (shellcheck)
- JSON validation
- Security checks

**View Results:**
```
https://github.com/phdsystems/project-management-automation/actions
```

## Running Locally

### Prerequisites

```bash
# Required tools
jq --version      # JSON processor
make --version    # Build automation
bash --version    # Shell (4.0+)
```

### Run All Tests

```bash
cd project-management
./tests/run-tests.sh
```

### Run Specific Test

```bash
# Run single test file
./tests/unit/test-gh-auth.sh

# Run single test type
./tests/run-tests.sh unit
```

### Debug Failed Tests

```bash
# Enable verbose output
VERBOSE=1 ./tests/run-tests.sh

# Check mock call log
cat /tmp/gh-automation-tests-*/mock-calls.log

# Inspect temp directory
ls -la /tmp/gh-automation-tests-*/
```

## Test Coverage

### Commands Tested

| Command | Unit | Integration | E2E |
|---------|------|-------------|-----|
| `gh auth status` | ✅ | ✅ | ✅ |
| `gh api /orgs/{org}/teams` | ✅ | ✅ | ✅ |
| `gh api /users/{user}` | ✅ | ✅ | ✅ |
| `gh repo create` | ✅ | ✅ | ✅ |
| `gh repo view` | ✅ | - | - |
| `jq` JSON parsing | ✅ | ✅ | ✅ |

### Makefile Targets Tested

| Target | Integration | E2E |
|--------|-------------|-----|
| `check-prereqs` | ✅ | ✅ |
| `teams` | ✅ | ✅ |
| `repos` | ✅ | ✅ |
| `readmes` | ✅ | ✅ |
| `workflows` | ✅ | ✅ |
| `codeowners` | ✅ | ✅ |
| `all` | - | ✅ |

### Scenarios Tested

- ✅ Valid organization account
- ✅ User account (error handling)
- ✅ Dry-run mode
- ✅ Idempotent operations
- ✅ Missing prerequisites
- ✅ Invalid configuration
- ✅ Empty teams/projects arrays
- ✅ Missing templates
- ✅ Multiple projects
- ✅ Template matching by role

## Common Issues

### Tests Fail with "Permission Denied"

```bash
# Make scripts executable
chmod +x tests/run-tests.sh
chmod +x tests/**/*.sh
chmod +x tests/mocks/*
```

### Mock Log Not Found

```bash
# Set MOCK_LOG environment variable
export MOCK_LOG="/tmp/test-mock.log"
```

### Temp Directory Not Cleaned

```bash
# Manual cleanup
rm -rf /tmp/gh-automation-tests-*
```

### PATH Issues with Mocks

```bash
# Verify mocks are in PATH
echo $PATH | grep "tests/mocks"

# Source test-helpers.sh properly
source "$(dirname "$0")/../test-helpers.sh"
```

## Contributing

### Adding New Tests

1. **Choose test type:** Unit, Integration, or E2E
2. **Create test file:** `tests/{type}/test-{name}.sh`
3. **Use template:** Copy from examples above
4. **Make executable:** `chmod +x tests/{type}/test-{name}.sh`
5. **Run locally:** `./tests/{type}/test-{name}.sh`
6. **Verify in CI:** Push to branch and check Actions

### Test Naming Convention

```
test-{component}-{scenario}.sh
```

**Examples:**
- `test-gh-auth.sh` - Tests gh auth commands
- `test-makefile-prereqs.sh` - Tests Makefile prerequisites
- `test-full-workflow.sh` - Tests complete workflow

### Best Practices

1. ✅ **One concern per test** - Test one thing clearly
2. ✅ **Clear assertions** - Use descriptive messages
3. ✅ **Clean up** - Always call `cleanup_test_env`
4. ✅ **Isolate tests** - Don't depend on other tests
5. ✅ **Mock external calls** - Don't hit real APIs
6. ✅ **Test error cases** - Not just happy paths
7. ✅ **Use fixtures** - Reuse test data

## Troubleshooting

### All Tests Pass Locally But Fail in CI

**Cause:** Environment differences

**Solution:**
- Check GitHub Actions logs
- Verify dependencies in CI
- Test with same Ubuntu version

### Intermittent Failures

**Cause:** Race conditions or temp file conflicts

**Solution:**
- Add unique PID to temp directories
- Use `set -e` for fail-fast
- Check for hardcoded paths

### Mock Not Working

**Cause:** PATH not set correctly

**Solution:**
```bash
# Verify mock is executable
ls -la tests/mocks/gh

# Check it's in PATH
which gh

# Should point to tests/mocks/gh
```

## Performance

**Typical run times:**

| Test Type | Count | Duration |
|-----------|-------|----------|
| Unit | 5 suites | ~5 seconds |
| Integration | 4 suites | ~10 seconds |
| E2E | 2 suites | ~15 seconds |
| **Total** | **11 suites** | **~30 seconds** |

## Future Enhancements

- [ ] Add performance benchmarks
- [ ] Add coverage reporting
- [ ] Add mutation testing
- [ ] Add contract tests for API responses
- [ ] Add visual regression tests for output
- [ ] Add load tests for large configurations
- [ ] Add security scanning for test code

---

**For questions or issues, see:**
- Main README: `../README.md`
- Test Report: `../TEST-REPORT.md`
- GitHub Issues: https://github.com/phdsystems/project-management-automation/issues

*Last Updated: 2025-10-27*
