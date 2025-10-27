#!/bin/bash
# Check command - Validate prerequisites
# Usage: gh-org check

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=internal/validation.sh
source "${SCRIPT_DIR}/../internal/validation.sh"

cmd::check::run() {
  local root_dir="$1"

  validation::check_prerequisites "$root_dir"
  return $?
}

cmd::check::help() {
  cat <<EOF
Check prerequisites for GitHub organization automation.

Usage:
  gh-org check

Description:
  Validates that all required tools, files, and configurations are present:
  - Checks for required CLI tools (gh, jq, git)
  - Validates .env file and configuration
  - Verifies GitHub authentication
  - Confirms template files exist

Examples:
  gh-org check

Options:
  -h, --help    Show this help message
EOF
}
