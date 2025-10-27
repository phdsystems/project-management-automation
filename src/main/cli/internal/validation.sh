#!/bin/bash
# Validation utilities for CLI
# Provides input validation and prerequisite checking

# Source output utilities
_INTERNAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=internal/output.sh
source "${_INTERNAL_DIR}/output.sh"

# Validate required environment variables
validation::check_env_var() {
  local var_name="$1"
  local var_value="${!var_name}"

  if [[ -z "$var_value" ]]; then
    output::error "Required environment variable not set: $var_name"
    return 1
  fi

  output::debug "Environment variable set: $var_name=$var_value"
  return 0
}

# Check if command exists
validation::check_command() {
  local cmd="$1"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    output::error "Required command not found: $cmd"
    return 1
  fi

  output::debug "Command available: $cmd"
  return 0
}

# Check if file exists
validation::check_file() {
  local file="$1"
  local description="${2:-File}"

  if [[ ! -f "$file" ]]; then
    output::error "$description not found: $file"
    return 1
  fi

  output::debug "File exists: $file"
  return 0
}

# Check if directory exists
validation::check_directory() {
  local dir="$1"
  local description="${2:-Directory}"

  if [[ ! -d "$dir" ]]; then
    output::error "$description not found: $dir"
    return 1
  fi

  output::debug "Directory exists: $dir"
  return 0
}

# Validate JSON file
validation::validate_json() {
  local file="$1"

  if ! jq empty "$file" 2>/dev/null; then
    output::error "Invalid JSON in file: $file"
    return 1
  fi

  output::debug "Valid JSON: $file"
  return 0
}

# Check all prerequisites
validation::check_prerequisites() {
  local root_dir="$1"
  local errors=0

  output::header "Checking prerequisites..."

  # Check .env file
  if ! validation::check_file "${root_dir}/.env" ".env file"; then
    output::info "Copy .env.example to .env and configure it"
    ((errors++))
  fi

  # Check required commands
  for cmd in gh jq git; do
    if ! validation::check_command "$cmd"; then
      ((errors++))
    fi
  done

  # Check config file
  if ! validation::check_file "${root_dir}/project-config.json" "Configuration file"; then
    ((errors++))
  else
    # Validate JSON
    if ! validation::validate_json "${root_dir}/project-config.json"; then
      ((errors++))
    fi
  fi

  # Check GitHub authentication
  if ! gh auth status >/dev/null 2>&1; then
    output::error "Not authenticated with GitHub"
    output::info "Run: gh auth login"
    ((errors++))
  else
    output::debug "GitHub authentication: OK"
  fi

  # Check templates directory
  if ! validation::check_directory "${root_dir}/src/main/templates" "Templates directory"; then
    ((errors++))
  fi

  if [[ $errors -gt 0 ]]; then
    output::error "Prerequisites check failed with $errors error(s)"
    return 1
  fi

  output::success "All prerequisites met"
  return 0
}
