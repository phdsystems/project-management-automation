#!/bin/bash
# Repos command - Manage GitHub repositories
# Usage: gh-org repos create

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=internal/output.sh
source "${SCRIPT_DIR}/../internal/output.sh"
# shellcheck source=pkg/config.sh
source "${SCRIPT_DIR}/../pkg/config.sh"
# shellcheck source=pkg/github.sh
source "${SCRIPT_DIR}/../pkg/github.sh"

cmd::repos::create() {
  local root_dir="$1"
  local dry_run="${2:-0}"

  output::header "Creating GitHub repositories"

  # Load configuration
  config::load_env "$root_dir" || return 1

  local org
  org=$(config::get_org)
  local config_file="${root_dir}/project-config.json"

  # Get all repos from config
  local repos
  repos=$(config::get_all_repos "$config_file") || return 1

  local errors=0

  # Create each repository
  while IFS= read -r repo_json; do
    if [[ -n "$repo_json" ]]; then
      local project
      local repo
      local team
      local permission

      project=$(echo "$repo_json" | jq -r '.project')
      repo=$(echo "$repo_json" | jq -r '.repo')
      team=$(echo "$repo_json" | jq -r '.team')
      permission=$(echo "$repo_json" | jq -r '.permission')

      # Build repository name: project-{project}-{repo}
      local repo_name="project-${project}-${repo}"

      output::info "Processing: $repo_name"

      # Create repository
      if ! github::create_repo "$org" "$repo_name" "$dry_run"; then
        ((errors++))
        continue
      fi

      # Assign team to repository
      if ! github::assign_team "$org" "$repo_name" "$team" "$permission" "$dry_run"; then
        ((errors++))
      fi
    fi
  done <<< "$repos"

  if [[ $errors -gt 0 ]]; then
    output::error "Failed to create/configure $errors repo(s)"
    return 1
  fi

  output::success "All repositories created and configured successfully"
  return 0
}

cmd::repos::run() {
  local subcommand="${1:-create}"
  local root_dir="$2"
  local dry_run="${3:-0}"

  case "$subcommand" in
    create)
      cmd::repos::create "$root_dir" "$dry_run"
      ;;
    help|--help|-h)
      cmd::repos::help
      ;;
    *)
      output::error "Unknown subcommand: $subcommand"
      cmd::repos::help
      return 1
      ;;
  esac
}

cmd::repos::help() {
  cat <<EOF
Manage GitHub repositories.

Usage:
  gh-org repos create [--dry-run]

Subcommands:
  create    Create repositories from configuration

Description:
  Creates private GitHub repositories and assigns teams with specified permissions.
  Repository names follow the pattern: project-{project}-{repo}

  The command is idempotent - it will skip repositories that already exist.

Examples:
  # Create repositories
  gh-org repos create

  # Preview without creating
  gh-org repos create --dry-run

Options:
  --dry-run     Preview changes without executing
  -h, --help    Show this help message

Configuration:
  Repositories are defined in project-config.json:
  {
    "projects": [
      {
        "name": "alpha",
        "repos": [
          {"name": "frontend", "team": "frontend-team", "permission": "push"},
          {"name": "backend", "team": "backend-team", "permission": "push"}
        ]
      }
    ]
  }

  This creates:
  - project-alpha-frontend (assigned to frontend-team with push permission)
  - project-alpha-backend (assigned to backend-team with push permission)

Permissions:
  - pull      Read-only access
  - push      Read + write access
  - maintain  Push + manage issues/PRs
  - admin     Full admin access
  - triage    Read + manage issues/PRs (no code)
EOF
}
