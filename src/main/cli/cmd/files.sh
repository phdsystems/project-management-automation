#!/bin/bash
# Files command - Manage template files in repositories
# Usage: gh-org files {readme|workflow|codeowners}

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=internal/output.sh
source "${SCRIPT_DIR}/../internal/output.sh"
# shellcheck source=pkg/config.sh
source "${SCRIPT_DIR}/../pkg/config.sh"
# shellcheck source=pkg/github.sh
source "${SCRIPT_DIR}/../pkg/github.sh"
# shellcheck source=pkg/templates.sh
source "${SCRIPT_DIR}/../pkg/templates.sh"

cmd::files::readme() {
  local root_dir="$1"
  local dry_run="${2:-0}"

  output::header "Adding README files to repositories"

  # Load configuration
  config::load_env "$root_dir" || return 1

  local org
  org=$(config::get_org)
  local config_file="${root_dir}/project-config.json"
  local templates_dir
  templates_dir=$(templates::get_dir "$root_dir")
  local tmp_dir="${root_dir}/.tmp-repos"

  # Create temp directory
  mkdir -p "$tmp_dir"

  # Get all repos
  local repos
  repos=$(config::get_all_repos "$config_file") || return 1

  local errors=0

  # Process each repository
  while IFS= read -r repo_json; do
    if [[ -n "$repo_json" ]]; then
      local project repo role repo_name
      project=$(echo "$repo_json" | jq -r '.project')
      repo=$(echo "$repo_json" | jq -r '.repo')
      role=$(echo "$repo_json" | jq -r '.repo')
      repo_name="project-${project}-${repo}"

      output::info "Processing: $repo_name"

      if [[ "$dry_run" == "1" ]]; then
        output::dry_run "Would add README to $repo_name (role: $role)"
        continue
      fi

      # Get template file
      local template_file
      template_file=$(templates::get_readme "$templates_dir" "$role") || {
        ((errors++))
        continue
      }

      # Clone repository
      local repo_dir="${tmp_dir}/${repo_name}"
      rm -rf "$repo_dir"

      if ! github::clone_repo "$org" "$repo_name" "$repo_dir"; then
        ((errors++))
        continue
      fi

      # Apply template
      if ! templates::apply_readme "$repo_dir" "$template_file"; then
        ((errors++))
        rm -rf "$repo_dir"
        continue
      fi

      # Commit and push
      if ! github::commit_and_push "$repo_dir" "docs: add README template for $role" "0"; then
        ((errors++))
      fi

      # Cleanup
      rm -rf "$repo_dir"
    fi
  done <<< "$repos"

  if [[ $errors -gt 0 ]]; then
    output::error "Failed to add README to $errors repo(s)"
    return 1
  fi

  output::success "README files added to all repositories"
  return 0
}

cmd::files::workflow() {
  local root_dir="$1"
  local dry_run="${2:-0}"

  output::header "Adding workflow files to repositories"

  # Load configuration
  config::load_env "$root_dir" || return 1

  local org
  org=$(config::get_org)
  local config_file="${root_dir}/project-config.json"
  local templates_dir
  templates_dir=$(templates::get_dir "$root_dir")
  local tmp_dir="${root_dir}/.tmp-repos"

  # Create temp directory
  mkdir -p "$tmp_dir"

  # Get all repos
  local repos
  repos=$(config::get_all_repos "$config_file") || return 1

  local errors=0

  # Process each repository
  while IFS= read -r repo_json; do
    if [[ -n "$repo_json" ]]; then
      local project repo role repo_name
      project=$(echo "$repo_json" | jq -r '.project')
      repo=$(echo "$repo_json" | jq -r '.repo')
      role=$(echo "$repo_json" | jq -r '.repo')
      repo_name="project-${project}-${repo}"

      output::info "Processing: $repo_name"

      if [[ "$dry_run" == "1" ]]; then
        output::dry_run "Would add workflow to $repo_name (role: $role)"
        continue
      fi

      # Get template file
      local template_file
      template_file=$(templates::get_workflow "$templates_dir" "$role") || {
        ((errors++))
        continue
      }

      # Clone repository
      local repo_dir="${tmp_dir}/${repo_name}"
      rm -rf "$repo_dir"

      if ! github::clone_repo "$org" "$repo_name" "$repo_dir"; then
        ((errors++))
        continue
      fi

      # Apply template
      if ! templates::apply_workflow "$repo_dir" "$template_file"; then
        ((errors++))
        rm -rf "$repo_dir"
        continue
      fi

      # Commit and push
      if ! github::commit_and_push "$repo_dir" "ci: add GitHub Actions workflow for $role" "0"; then
        ((errors++))
      fi

      # Cleanup
      rm -rf "$repo_dir"
    fi
  done <<< "$repos"

  if [[ $errors -gt 0 ]]; then
    output::error "Failed to add workflow to $errors repo(s)"
    return 1
  fi

  output::success "Workflow files added to all repositories"
  return 0
}

cmd::files::codeowners() {
  local root_dir="$1"
  local dry_run="${2:-0}"

  output::header "Adding CODEOWNERS files to repositories"

  # Load configuration
  config::load_env "$root_dir" || return 1

  local org
  org=$(config::get_org)
  local config_file="${root_dir}/project-config.json"
  local templates_dir
  templates_dir=$(templates::get_dir "$root_dir")
  local tmp_dir="${root_dir}/.tmp-repos"

  # Create temp directory
  mkdir -p "$tmp_dir"

  # Get template file
  local template_file
  template_file=$(templates::get_codeowners "$templates_dir") || return 1

  # Get all repos
  local repos
  repos=$(config::get_all_repos "$config_file") || return 1

  local errors=0

  # Process each repository
  while IFS= read -r repo_json; do
    if [[ -n "$repo_json" ]]; then
      local project repo repo_name
      project=$(echo "$repo_json" | jq -r '.project')
      repo=$(echo "$repo_json" | jq -r '.repo')
      repo_name="project-${project}-${repo}"

      output::info "Processing: $repo_name"

      if [[ "$dry_run" == "1" ]]; then
        output::dry_run "Would add CODEOWNERS to $repo_name"
        continue
      fi

      # Clone repository
      local repo_dir="${tmp_dir}/${repo_name}"
      rm -rf "$repo_dir"

      if ! github::clone_repo "$org" "$repo_name" "$repo_dir"; then
        ((errors++))
        continue
      fi

      # Apply template
      if ! templates::apply_codeowners "$repo_dir" "$template_file"; then
        ((errors++))
        rm -rf "$repo_dir"
        continue
      fi

      # Commit and push
      if ! github::commit_and_push "$repo_dir" "chore: add CODEOWNERS file" "0"; then
        ((errors++))
      fi

      # Cleanup
      rm -rf "$repo_dir"
    fi
  done <<< "$repos"

  if [[ $errors -gt 0 ]]; then
    output::error "Failed to add CODEOWNERS to $errors repo(s)"
    return 1
  fi

  output::success "CODEOWNERS files added to all repositories"
  return 0
}

cmd::files::run() {
  local subcommand="${1:-}"
  local root_dir="$2"
  local dry_run="${3:-0}"

  case "$subcommand" in
    readme)
      cmd::files::readme "$root_dir" "$dry_run"
      ;;
    workflow)
      cmd::files::workflow "$root_dir" "$dry_run"
      ;;
    codeowners)
      cmd::files::codeowners "$root_dir" "$dry_run"
      ;;
    help|--help|-h|"")
      cmd::files::help
      ;;
    *)
      output::error "Unknown subcommand: $subcommand"
      cmd::files::help
      return 1
      ;;
  esac
}

cmd::files::help() {
  cat <<EOF
Manage template files in repositories.

Usage:
  gh-org files {readme|workflow|codeowners} [--dry-run]

Subcommands:
  readme        Add README templates to repositories
  workflow      Add GitHub Actions workflow templates
  codeowners    Add CODEOWNERS files

Description:
  Clones repositories, applies template files, and commits changes.
  Template selection is based on repository role (frontend/backend/infra).

Examples:
  # Add README files
  gh-org files readme

  # Add workflow files
  gh-org files workflow

  # Add CODEOWNERS files
  gh-org files codeowners

  # Preview without applying
  gh-org files readme --dry-run

Options:
  --dry-run     Preview changes without executing
  -h, --help    Show this help message

Templates:
  - README: src/main/templates/README-{role}.md
  - Workflow: src/main/templates/workflow-{role}.yml
  - CODEOWNERS: src/main/templates/CODEOWNERS
EOF
}
