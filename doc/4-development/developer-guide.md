# Developer Guide

**Version:** 1.0.0
**Last Updated:** 2025-10-27

## TL;DR

**Architecture**: Modular CLI (cmd/pkg/internal) with backend router pattern supporting GitHub/Gitea. **Key files**: `pkg/backend.sh` (router), `pkg/github.sh` + `pkg/gitea.sh` (implementations). **Adding features**: Create in `cmd/`, use backend router, test both platforms. **Code style**: Shellcheck clean, functions prefixed by module, error handling required. **Testing**: Unit + integration tests, both backends. **PR process**: Feature branch → tests → shellcheck → docs → PR.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Code Organization](#code-organization)
- [Development Practices](#development-practices)
- [Adding New Features](#adding-new-features)
- [Backend Development](#backend-development)
- [Testing Guidelines](#testing-guidelines)
- [Code Style](#code-style)
- [Common Tasks](#common-tasks)
- [Pull Request Process](#pull-request-process)
- [Debugging](#debugging)
- [Performance Considerations](#performance-considerations)

---

## Overview

### Project Purpose

Automate Git platform organization setup (teams, repositories, templates) with support for both GitHub and Gitea through a unified CLI interface.

### Key Design Principles

1. **Platform Agnostic** - Same config works for GitHub and Gitea
2. **Backend Abstraction** - Router pattern isolates platform-specific code
3. **Idempotent** - Safe to run multiple times
4. **Modular** - Clear separation of concerns (cmd/pkg/internal)
5. **Testable** - Unit and integration tests for all features

### Tech Stack

- **Language**: Bash 4.0+
- **CLI Framework**: Custom (inspired by GitHub CLI)
- **Config Format**: JSON (parsed with jq)
- **Backends**: GitHub (gh CLI), Gitea (tea CLI + API)
- **Testing**: Custom test framework

---

## Architecture

### High-Level Architecture

```
┌──────────────────────────────────────┐
│          CLI Entry Point             │
│           (gh-org)                   │
└──────────────┬───────────────────────┘
               │
    ┌──────────┴──────────┐
    │   Command Layer     │
    │      (cmd/)         │
    │  ┌────────────────┐ │
    │  │ teams.sh       │ │
    │  │ repos.sh       │ │
    │  │ files.sh       │ │
    │  │ setup.sh       │ │
    │  └────────────────┘ │
    └──────────┬──────────┘
               │
    ┌──────────┴──────────┐
    │    Core Logic       │
    │      (pkg/)         │
    │  ┌────────────────┐ │
    │  │ backend.sh     │◄├─ Router
    │  │ config.sh      │ │
    │  │ templates.sh   │ │
    │  └────┬───────────┘ │
    └───────┼─────────────┘
            │
     ┌──────┴───────┐
     │              │
┌────▼────┐   ┌────▼────┐
│ github  │   │ gitea   │
│ .sh     │   │ .sh     │
└────┬────┘   └────┬────┘
     │              │
┌────▼────┐   ┌────▼────┐
│ gh CLI  │   │tea CLI  │
│         │   │+ API    │
└─────────┘   └─────────┘
```

### Backend Router Pattern

**Key concept**: Commands call `backend::*` functions, which route to `github::*` or `gitea::*` based on `$BACKEND` environment variable.

**Example:**
```bash
# Command (cmd/teams.sh)
backend::create_team "$org" "$team" "$dry_run"

# Router (pkg/backend.sh)
backend::create_team() {
  if config::is_gitea; then
    gitea::create_team "$@"
  else
    github::create_team "$@"
  fi
}

# Implementations
github::create_team() { ... }  # Uses gh CLI
gitea::create_team() { ... }   # Uses tea CLI + API
```

### Module Responsibilities

| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **cmd/** | Command handlers | Parse args, orchestrate operations |
| **pkg/backend.sh** | Backend router | Route operations to correct backend |
| **pkg/github.sh** | GitHub impl | GitHub API operations via gh CLI |
| **pkg/gitea.sh** | Gitea impl | Gitea API operations via tea CLI + curl |
| **pkg/config.sh** | Configuration | Load .env, parse JSON, detect backend |
| **pkg/templates.sh** | Templates | Match and apply template files |
| **internal/output.sh** | Pretty output | Colored messages, formatting |
| **internal/validation.sh** | Prerequisites | Check tools, auth, config |

---

## Code Organization

### Directory Structure

```
src/main/cli/
├── gh-org                          # Entry point (executable)
│
├── cmd/                            # Command handlers
│   ├── check.sh                   # Prerequisites check
│   ├── teams.sh                   # Team management
│   ├── repos.sh                   # Repository management
│   ├── files.sh                   # File templates (README, etc.)
│   └── setup.sh                   # Complete automation workflow
│
├── pkg/                            # Core business logic
│   ├── backend.sh                 # Backend router (CRITICAL)
│   ├── github.sh                  # GitHub implementation
│   ├── gitea.sh                   # Gitea implementation
│   ├── config.sh                  # Configuration management
│   └── templates.sh               # Template engine
│
├── internal/                       # Utilities (internal use only)
│   ├── output.sh                  # Pretty printing
│   └── validation.sh              # Prerequisites validation
│
└── templates/                      # Template files
    ├── README-frontend.md
    ├── README-backend.md
    ├── workflow-frontend.yml
    └── CODEOWNERS
```

### File Naming Conventions

- **Executables**: No extension (`gh-org`)
- **Bash modules**: `.sh` extension
- **Functions**: Prefixed with module name (`backend::`, `github::`, etc.)
- **Private functions**: Prefix with underscore (`_internal::helper()`)

### Function Naming

```bash
# Module functions (public API)
backend::create_team()
github::create_repo()
config::load_env()

# Private helpers (internal to module)
_github::parse_response()
_config::validate_org_name()

# Command handlers
cmd::teams::create()
cmd::setup::run()
```

---

## Development Practices

### Code Style

**Follow these conventions:**

1. **Use shellcheck**: All code must pass `shellcheck`
2. **Function prefixes**: Always use module prefix (`backend::`, `github::`)
3. **Error handling**: Always check return codes
4. **Quoting**: Quote all variables (`"$var"`, not `$var`)
5. **Local variables**: Use `local` for function variables
6. **Documentation**: Add comments for non-obvious logic

**Good example:**
```bash
# Create a GitHub team
github::create_team() {
  local org="$1"
  local team="$2"
  local dry_run="${3:-0}"

  if [[ "$dry_run" == "1" ]]; then
    output::dry_run "Would create team: $team"
    return 0
  fi

  # Check if team exists (idempotent)
  if gh api "/orgs/${org}/teams" --jq ".[] | select(.name == \"$team\") | .name" 2>/dev/null | grep -q "^${team}$"; then
    output::info "Team already exists: $team"
    return 0
  fi

  output::info "Creating team: $team"
  if gh api -X POST "/orgs/${org}/teams" -f name="$team" -f privacy="closed" >/dev/null 2>&1; then
    output::success "Team created: $team"
    return 0
  else
    output::error "Failed to create team: $team"
    return 1
  fi
}
```

### Error Handling

**Always handle errors:**

```bash
# Bad
result=$(some_command)
process "$result"

# Good
local result
if ! result=$(some_command 2>&1); then
  output::error "Command failed: some_command"
  return 1
fi

if ! process "$result"; then
  output::error "Processing failed"
  return 1
fi
```

### Output Standards

**Use output functions consistently:**

```bash
output::header "Creating teams"       # Section headers
output::info "Processing: team-name"  # Informational
output::success "Team created"        # Success messages
output::warning "Team exists"         # Warnings
output::error "Failed to create"      # Errors
output::debug "API response: ..."     # Debug info
output::dry_run "Would create..."     # Dry-run preview
```

---

## Adding New Features

### Step-by-Step Guide

#### 1. Plan the Feature

**Questions to answer:**
- What problem does this solve?
- Which commands are affected?
- Does it need backend-specific implementation?
- What configuration is needed?
- How will it be tested?

#### 2. Update Configuration (if needed)

```bash
# If adding new config fields, update:
# - .env.example (environment variables)
# - project-config.json (structure)
# - pkg/config.sh (parsing logic)
```

#### 3. Implement Backend Logic

**If feature needs backend operations:**

```bash
# 1. Add to backend router (pkg/backend.sh)
backend::new_operation() {
  local param="$1"

  if config::is_gitea; then
    gitea::new_operation "$param"
  else
    github::new_operation "$param"
  fi
}

# 2. Implement for GitHub (pkg/github.sh)
github::new_operation() {
  local param="$1"
  # Use gh CLI
  gh api ...
}

# 3. Implement for Gitea (pkg/gitea.sh)
gitea::new_operation() {
  local param="$1"
  # Use tea CLI or curl API
  curl -X POST ...
}
```

#### 4. Add Command Handler

```bash
# Add to cmd/your-command.sh

cmd::yourcommand::run() {
  local subcommand="${1:-}"
  local root_dir="$2"
  local dry_run="${3:-0}"

  # Load configuration
  config::load_env "$root_dir" || return 1

  local org
  org=$(config::get_org)

  # Use backend operations
  backend::new_operation "$param" "$dry_run"
}
```

#### 5. Add Tests

```bash
# Add to src/test/

# Unit test
test_new_operation() {
  # Setup
  export BACKEND=github

  # Execute
  result=$(backend::new_operation "param")

  # Assert
  assert_equals "expected" "$result"
}

# Integration test
test_new_operation_integration() {
  # Test with real backend
  ./src/main/cli/gh-org your-command

  # Verify results
  verify_operation_succeeded
}
```

#### 6. Update Documentation

```bash
# Update:
# - README.md (if user-facing)
# - doc/cli-guide.md (CLI reference)
# - doc/user-guide.md (usage examples)
# - Command help text (cmd/your-command.sh)
```

#### 7. Submit Pull Request

```bash
git checkout -b feature/your-feature
git add .
git commit -m "feat(cli): add new feature"
git push origin feature/your-feature
gh pr create
```

---

## Backend Development

### Adding a New Backend

**Example: Adding GitLab support**

#### 1. Create Implementation File

```bash
# src/main/cli/pkg/gitlab.sh

#!/bin/bash
# GitLab API interactions

# Create team (group in GitLab)
gitlab::create_team() {
  local org="$1"
  local team="$2"
  local dry_run="${3:-0}"

  # Implementation using glab CLI
  glab api -X POST "/groups" -f name="$team" ...
}

# Create repository
gitlab::create_repo() {
  local org="$1"
  local repo="$2"
  local dry_run="${3:-0}"

  glab repo create "$org/$repo" --private
}

# ... other operations
```

#### 2. Update Backend Router

```bash
# pkg/backend.sh

# Source new backend
source "${_PKG_DIR}/gitlab.sh"

# Update router functions
backend::create_team() {
  local org="$1"
  local team="$2"
  local dry_run="${3:-0}"

  case "$(config::get_backend)" in
    github)
      github::create_team "$org" "$team" "$dry_run"
      ;;
    gitea)
      gitea::create_team "$org" "$team" "$dry_run"
      ;;
    gitlab)
      gitlab::create_team "$org" "$team" "$dry_run"
      ;;
    *)
      output::error "Unknown backend: $(config::get_backend)"
      return 1
      ;;
  esac
}
```

#### 3. Update Configuration Detection

```bash
# pkg/config.sh

config::is_gitlab() {
  [[ "${CONFIG_BACKEND:-github}" == "gitlab" ]]
}

config::get_backend_name() {
  case "$(config::get_backend)" in
    github) echo "GitHub" ;;
    gitea) echo "Gitea" ;;
    gitlab) echo "GitLab" ;;
    *) echo "Unknown" ;;
  esac
}
```

#### 4. Update Validation

```bash
# internal/validation.sh

# Add GitLab CLI check
if [[ "$backend" == "gitlab" ]]; then
  if ! validation::check_command "glab"; then
    output::error "GitLab CLI not found"
    output::info "Install: https://gitlab.com/gitlab-org/cli"
    ((errors++))
  fi

  if ! glab auth status >/dev/null 2>&1; then
    output::error "Not authenticated with GitLab"
    output::info "Run: glab auth login"
    ((errors++))
  fi
fi
```

#### 5. Add Documentation

```bash
# Create doc/gitlab-guide.md
# Update .env.example: BACKEND=gitlab
# Update README.md
```

### Backend Interface Contract

**Every backend implementation must provide:**

```bash
# Required functions
backend_name::create_team(org, team, dry_run)
backend_name::create_repo(org, repo, dry_run)
backend_name::assign_team(org, repo, team, permission, dry_run)
backend_name::clone_repo(org, repo, dest)
backend_name::commit_and_push(repo_dir, commit_msg, dry_run)

# Helper functions
backend_name::check_auth()
backend_name::get_url()
```

**Function signatures must match:**
- Same parameter order
- Same return codes (0 = success, 1 = failure)
- Same dry-run behavior
- Same output messages (use output:: functions)

---

## Testing Guidelines

### Test Structure

```
src/test/
├── unit/                   # Unit tests
│   ├── test-config.sh     # Config parsing
│   ├── test-backend.sh    # Backend routing
│   └── test-templates.sh  # Template matching
│
├── integration/            # Integration tests
│   ├── test-github.sh     # GitHub operations
│   ├── test-gitea.sh      # Gitea operations
│   └── test-e2e.sh        # End-to-end workflows
│
└── fixtures/               # Test data
    ├── config-valid.json
    ├── config-invalid.json
    └── test-templates/
```

### Writing Unit Tests

```bash
# src/test/unit/test-myfeature.sh

#!/bin/bash

# Setup
source "$(dirname "$0")/../../main/cli/pkg/backend.sh"

# Test case
test_backend_routing_github() {
  # Arrange
  export BACKEND=github
  local org="test-org"
  local team="test-team"

  # Act
  result=$(backend::create_team "$org" "$team" "1")  # dry-run

  # Assert
  if [[ "$result" != *"Would create team: test-team"* ]]; then
    echo "FAIL: Expected dry-run message"
    return 1
  fi

  echo "PASS: Backend routing works"
  return 0
}

# Run test
test_backend_routing_github
```

### Writing Integration Tests

```bash
# src/test/integration/test-teams.sh

#!/bin/bash

test_teams_create_idempotent() {
  # Setup
  export BACKEND=gitea  # Use test Gitea instance
  export ORG=test-org

  # First run - creates team
  ./src/main/cli/gh-org teams create
  result1=$?

  # Second run - should be idempotent
  ./src/main/cli/gh-org teams create
  result2=$?

  # Assert
  if [[ $result1 -ne 0 ]] || [[ $result2 -ne 0 ]]; then
    echo "FAIL: Teams creation not idempotent"
    return 1
  fi

  # Verify team exists
  if ! tea teams list --organization "$ORG" | grep -q "test-team"; then
    echo "FAIL: Team not found"
    return 1
  fi

  echo "PASS: Teams creation is idempotent"
  return 0
}

test_teams_create_idempotent
```

### Running Tests

```bash
# Run all tests
make -C src/test all

# Run specific test category
make -C src/test unit
make -C src/test integration

# Run specific test file
bash src/test/unit/test-config.sh

# Run with verbose output
VERBOSE=1 make -C src/test all
```

### Test Best Practices

1. **Use test fixtures** - Don't hardcode test data
2. **Clean up after tests** - Remove created resources
3. **Test both backends** - GitHub and Gitea
4. **Test error paths** - Not just happy paths
5. **Use dry-run mode** - For unit tests (faster, no side effects)
6. **Verify idempotency** - Run operations twice

---

## Code Style

### Shellcheck

**All code must pass shellcheck:**

```bash
# Install shellcheck
sudo apt install shellcheck  # Ubuntu/Debian
brew install shellcheck      # macOS

# Check single file
shellcheck src/main/cli/pkg/backend.sh

# Check all files
find src/main/cli -name "*.sh" -exec shellcheck {} +

# Fix common issues automatically
shellcheck -f diff src/main/cli/pkg/backend.sh | git apply
```

### Bash Style Guide

**Follow these rules:**

#### Variables

```bash
# Good
local my_var="value"
local another_var="${my_var}"

# Bad
my_var=value          # Missing local
another_var=$my_var   # Missing quotes
```

#### Quoting

```bash
# Good
if [[ "$var" == "value" ]]; then
  echo "Result: $var"
fi

# Bad
if [ $var == value ]; then
  echo Result: $var
fi
```

#### Error Handling

```bash
# Good
if ! command_that_might_fail; then
  output::error "Command failed"
  return 1
fi

# Bad
command_that_might_fail  # Ignores errors
```

#### Functions

```bash
# Good
module::function_name() {
  local param="$1"
  local result

  if ! result=$(operation "$param"); then
    return 1
  fi

  echo "$result"
  return 0
}

# Bad
function_name() {  # No module prefix
  result=$(operation $1)  # No error handling, missing quotes
  echo $result            # Missing quotes
}
```

---

## Common Tasks

### Adding a New Command

```bash
# 1. Create command file
cat > src/main/cli/cmd/mycommand.sh << 'EOF'
#!/bin/bash
# My command - Does something useful

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../internal/output.sh"
source "${SCRIPT_DIR}/../pkg/config.sh"
source "${SCRIPT_DIR}/../pkg/backend.sh"

cmd::mycommand::run() {
  local subcommand="${1:-}"
  local root_dir="$2"
  local dry_run="${3:-0}"

  output::header "Running my command"

  # Implementation
  backend::some_operation "$dry_run"
}

cmd::mycommand::help() {
  cat <<EOF
My command does something useful.

Usage:
  gh-org mycommand [options]

Options:
  --dry-run     Preview changes without executing
  -h, --help    Show this help message
EOF
}
EOF

# 2. Add to main CLI
# Edit src/main/cli/gh-org, add:
mycommand)
  cmd::mycommand::run "$subcommand" "$ROOT_DIR" "$DRY_RUN"
  ;;

# 3. Source in gh-org
source "${SCRIPT_DIR}/cmd/mycommand.sh"

# 4. Add tests
# Create src/test/integration/test-mycommand.sh

# 5. Update documentation
# Update doc/cli-guide.md
```

### Adding a Template

```bash
# 1. Create template file
cat > src/main/templates/README-mobile.md << 'EOF'
# Mobile Application

## Overview

This is a mobile application.

## Setup

```bash
npm install
npm run start
```
EOF

# 2. Update template matcher (if needed)
# Edit pkg/templates.sh

templates::get_readme() {
  local templates_dir="$1"
  local role="$2"

  # Add mobile case
  case "$role" in
    mobile)
      echo "${templates_dir}/README-mobile.md"
      ;;
    # ... existing cases
  esac
}

# 3. Test
echo '{"name":"mobile","team":"mobile-team","permission":"push"}' | \
  jq -r '.name' # Should output: mobile
```

### Debugging Backend Issues

```bash
# 1. Enable debug output
export VERBOSE=1

# 2. Check backend detection
source src/main/cli/pkg/config.sh
config::load_env "."
echo "Backend: $(config::get_backend)"
echo "Is GitHub: $(config::is_github && echo yes || echo no)"
echo "Is Gitea: $(config::is_gitea && echo yes || echo no)"

# 3. Test backend operations in isolation
source src/main/cli/pkg/backend.sh
source src/main/cli/pkg/github.sh
source src/main/cli/pkg/gitea.sh

# Test specific operation
backend::create_team "test-org" "test-team" "1"  # dry-run

# 4. Check API calls (Gitea)
curl -X GET -H "Authorization: token $TOKEN" \
  http://172.17.0.3:3000/api/v1/orgs/test-org/teams

# 5. Check CLI tools
gh auth status
tea login list
```

---

## Pull Request Process

### Before Creating PR

```bash
# 1. Run tests
make -C src/test all

# 2. Run shellcheck
find src/main/cli -name "*.sh" -exec shellcheck {} +

# 3. Update documentation
# - Update relevant docs in doc/
# - Update command help text
# - Add/update examples

# 4. Test both backends
export BACKEND=github
./src/main/cli/gh-org check

export BACKEND=gitea
./src/main/cli/gh-org check

# 5. Commit with conventional commit format
git commit -m "feat(cli): add new feature"
# or
git commit -m "fix(gitea): resolve authentication issue"
```

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Tested with GitHub
- [ ] Tested with Gitea
- [ ] Shellcheck passes

## Documentation
- [ ] Updated relevant docs
- [ ] Updated command help
- [ ] Added examples (if needed)

## Checklist
- [ ] Code follows style guidelines
- [ ] Commits follow conventional format
- [ ] No breaking changes (or documented)
- [ ] All tests pass
```

---

## Debugging

### Common Debugging Techniques

**Enable verbose output:**
```bash
export VERBOSE=1
./src/main/cli/gh-org teams create
```

**Add debug statements:**
```bash
output::debug "Variable value: $my_var"
output::debug "API response: $response"
```

**Test functions in isolation:**
```bash
# Source files
source src/main/cli/pkg/backend.sh
source src/main/cli/internal/output.sh

# Call function directly
backend::create_team "org" "team" "1"
```

**Check return codes:**
```bash
./src/main/cli/gh-org teams create
echo "Exit code: $?"  # 0 = success, 1 = failure
```

### Debugging Backend Issues

See [Common Tasks](#common-tasks) → Debugging Backend Issues

---

## Performance Considerations

### Optimization Tips

1. **Batch API calls** - Minimize API requests
2. **Use dry-run for testing** - Faster, no side effects
3. **Cache API responses** - If making repeated calls
4. **Parallel operations** - Future enhancement (not implemented)
5. **Avoid unnecessary clones** - Check if repo exists first

### Performance Benchmarks

| Operation | GitHub | Gitea (local) |
|-----------|--------|---------------|
| Create team | ~1s | ~0.5s |
| Create repo | ~2s | ~1s |
| Clone repo | 5-10s | 1-2s (local) |
| Commit + push | 3-5s | 1-2s (local) |

**Local Gitea is significantly faster due to no network latency.**

---

## Resources

### Documentation

- [Local Setup](local-setup.md) - Development environment setup
- [Architecture](../3-design/architecture.md) - System architecture
- [User Guide](../user-guide.md) - User-facing documentation
- [CLI Guide](../cli-guide.md) - CLI reference

### External Resources

- **Bash Style Guide**: https://google.github.io/styleguide/shellguide.html
- **Shellcheck**: https://www.shellcheck.net/
- **GitHub CLI**: https://cli.github.com/manual/
- **Gitea API**: https://docs.gitea.io/en-us/api-usage/
- **tea CLI**: https://gitea.com/gitea/tea

### Community

- **Issues**: https://github.com/phdsystems/project-management-automation/issues
- **Discussions**: https://github.com/phdsystems/project-management-automation/discussions
- **Pull Requests**: https://github.com/phdsystems/project-management-automation/pulls

---

*Last Updated: 2025-10-27*
*Version: 1.0.0*
