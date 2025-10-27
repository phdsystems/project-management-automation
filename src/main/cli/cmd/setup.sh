#!/bin/bash
# Setup command - Run all setup operations
# Usage: gh-org setup

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=internal/output.sh
source "${SCRIPT_DIR}/../internal/output.sh"
# shellcheck source=internal/validation.sh
source "${SCRIPT_DIR}/../internal/validation.sh"
# shellcheck source=cmd/teams.sh
source "${SCRIPT_DIR}/teams.sh"
# shellcheck source=cmd/repos.sh
source "${SCRIPT_DIR}/repos.sh"
# shellcheck source=cmd/files.sh
source "${SCRIPT_DIR}/files.sh"

cmd::setup::run() {
  local root_dir="$1"
  local dry_run="${2:-0}"

  output::header "Running complete GitHub organization setup"

  # Check prerequisites first
  if ! validation::check_prerequisites "$root_dir"; then
    output::error "Prerequisites check failed. Fix issues and try again."
    return 1
  fi

  local errors=0

  # Step 1: Create teams
  output::header "Step 1/5: Creating teams"
  if ! cmd::teams::create "$root_dir" "$dry_run"; then
    output::error "Failed to create teams"
    ((errors++))
  fi
  echo ""

  # Step 2: Create repositories
  output::header "Step 2/5: Creating repositories"
  if ! cmd::repos::create "$root_dir" "$dry_run"; then
    output::error "Failed to create repositories"
    ((errors++))
  fi
  echo ""

  # Step 3: Add README files
  output::header "Step 3/5: Adding README files"
  if ! cmd::files::readme "$root_dir" "$dry_run"; then
    output::error "Failed to add README files"
    ((errors++))
  fi
  echo ""

  # Step 4: Add workflow files
  output::header "Step 4/5: Adding workflow files"
  if ! cmd::files::workflow "$root_dir" "$dry_run"; then
    output::error "Failed to add workflow files"
    ((errors++))
  fi
  echo ""

  # Step 5: Add CODEOWNERS files
  output::header "Step 5/5: Adding CODEOWNERS files"
  if ! cmd::files::codeowners "$root_dir" "$dry_run"; then
    output::error "Failed to add CODEOWNERS files"
    ((errors++))
  fi
  echo ""

  # Summary
  if [[ $errors -gt 0 ]]; then
    output::error "Setup completed with $errors error(s)"
    return 1
  fi

  output::success "Setup completed successfully!"
  output::info "Your GitHub organization is now configured"
  return 0
}

cmd::setup::help() {
  cat <<EOF
Run complete GitHub organization setup.

Usage:
  gh-org setup [--dry-run]

Description:
  Executes all setup steps in order:
  1. Check prerequisites
  2. Create teams
  3. Create repositories
  4. Add README files
  5. Add GitHub Actions workflows
  6. Add CODEOWNERS files

  This is equivalent to running:
    gh-org check
    gh-org teams create
    gh-org repos create
    gh-org files readme
    gh-org files workflow
    gh-org files codeowners

  The command is idempotent - safe to run multiple times.

Examples:
  # Run complete setup
  gh-org setup

  # Preview all changes without executing
  gh-org setup --dry-run

Options:
  --dry-run     Preview all changes without executing
  -h, --help    Show this help message

Notes:
  - Prerequisites are checked before any operations
  - Each step continues even if previous steps have errors
  - Final exit code indicates overall success/failure
EOF
}
