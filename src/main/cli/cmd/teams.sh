#!/bin/bash
# Teams command - Manage GitHub teams
# Usage: gh-org teams create

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=internal/output.sh
source "${SCRIPT_DIR}/../internal/output.sh"
# shellcheck source=pkg/config.sh
source "${SCRIPT_DIR}/../pkg/config.sh"
# shellcheck source=pkg/github.sh
source "${SCRIPT_DIR}/../pkg/github.sh"

cmd::teams::create() {
  local root_dir="$1"
  local dry_run="${2:-0}"

  output::header "Creating GitHub teams"

  # Load configuration
  config::load_env "$root_dir" || return 1

  local org
  org=$(config::get_org)
  local config_file="${root_dir}/project-config.json"

  # Get teams from config
  local teams
  teams=$(config::get_teams "$config_file") || return 1

  local errors=0

  # Create each team
  while IFS= read -r team; do
    if [[ -n "$team" ]]; then
      if ! github::create_team "$org" "$team" "$dry_run"; then
        ((errors++))
      fi
    fi
  done <<< "$teams"

  if [[ $errors -gt 0 ]]; then
    output::error "Failed to create $errors team(s)"
    return 1
  fi

  output::success "All teams created successfully"
  return 0
}

cmd::teams::run() {
  local subcommand="${1:-create}"
  local root_dir="$2"
  local dry_run="${3:-0}"

  case "$subcommand" in
    create)
      cmd::teams::create "$root_dir" "$dry_run"
      ;;
    help|--help|-h)
      cmd::teams::help
      ;;
    *)
      output::error "Unknown subcommand: $subcommand"
      cmd::teams::help
      return 1
      ;;
  esac
}

cmd::teams::help() {
  cat <<EOF
Manage GitHub teams.

Usage:
  gh-org teams create [--dry-run]

Subcommands:
  create    Create teams from configuration

Description:
  Creates GitHub teams as defined in project-config.json. Teams are created
  with 'closed' privacy setting (visible only to organization members).

  The command is idempotent - it will skip teams that already exist.

Examples:
  # Create teams
  gh-org teams create

  # Preview without creating
  gh-org teams create --dry-run

Options:
  --dry-run     Preview changes without executing
  -h, --help    Show this help message

Configuration:
  Teams are read from the 'teams' array in project-config.json:
  {
    "teams": ["frontend-team", "backend-team", "infra-team"]
  }
EOF
}
