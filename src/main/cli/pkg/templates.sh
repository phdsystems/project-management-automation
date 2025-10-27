#!/bin/bash
# Template file operations
# Handles copying and applying template files to repositories

# Source utilities
_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=internal/output.sh
source "${_PKG_DIR}/../internal/output.sh"

# Get template directory
templates::get_dir() {
  local root_dir="$1"
  echo "${root_dir}/src/main/templates"
}

# Get README template for role
templates::get_readme() {
  local templates_dir="$1"
  local role="$2"

  local template_file="${templates_dir}/README-${role}.md"

  if [[ ! -f "$template_file" ]]; then
    output::error "README template not found for role: $role"
    return 1
  fi

  echo "$template_file"
}

# Get workflow template for role
templates::get_workflow() {
  local templates_dir="$1"
  local role="$2"

  local template_file="${templates_dir}/workflow-${role}.yml"

  if [[ ! -f "$template_file" ]]; then
    output::error "Workflow template not found for role: $role"
    return 1
  fi

  echo "$template_file"
}

# Get CODEOWNERS template
templates::get_codeowners() {
  local templates_dir="$1"

  local template_file="${templates_dir}/CODEOWNERS"

  if [[ ! -f "$template_file" ]]; then
    output::error "CODEOWNERS template not found"
    return 1
  fi

  echo "$template_file"
}

# Copy README template to repository
templates::apply_readme() {
  local repo_dir="$1"
  local template_file="$2"

  output::debug "Applying README template: $template_file"

  if cp "$template_file" "${repo_dir}/README.md"; then
    output::success "README added"
    return 0
  else
    output::error "Failed to copy README template"
    return 1
  fi
}

# Copy workflow template to repository
templates::apply_workflow() {
  local repo_dir="$1"
  local template_file="$2"

  output::debug "Applying workflow template: $template_file"

  mkdir -p "${repo_dir}/.github/workflows"

  if cp "$template_file" "${repo_dir}/.github/workflows/ci.yml"; then
    output::success "Workflow added"
    return 0
  else
    output::error "Failed to copy workflow template"
    return 1
  fi
}

# Copy CODEOWNERS template to repository
templates::apply_codeowners() {
  local repo_dir="$1"
  local template_file="$2"

  output::debug "Applying CODEOWNERS template: $template_file"

  mkdir -p "${repo_dir}/.github"

  if cp "$template_file" "${repo_dir}/.github/CODEOWNERS"; then
    output::success "CODEOWNERS added"
    return 0
  else
    output::error "Failed to copy CODEOWNERS template"
    return 1
  fi
}

# Extract role from repository name
templates::extract_role() {
  local repo_name="$1"

  # Extract role from repo name (e.g., "project-alpha-frontend" -> "frontend")
  echo "$repo_name" | awk -F'-' '{print $NF}'
}
