#!/bin/bash
# Configuration management
# Handles loading and parsing configuration files

# Source utilities
_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=internal/output.sh
source "${_PKG_DIR}/../internal/output.sh"

# Global config variables
declare -g CONFIG_ORG
declare -g CONFIG_FILE
declare -g CONFIG_DRY_RUN
declare -g CONFIG_VERBOSE

# Load environment configuration
config::load_env() {
  local root_dir="$1"
  local env_file="${root_dir}/.env"

  if [[ ! -f "$env_file" ]]; then
    output::error ".env file not found"
    return 1
  fi

  # shellcheck source=/dev/null
  source "$env_file"

  CONFIG_ORG="${ORG}"
  CONFIG_FILE="${root_dir}/project-config.json"
  CONFIG_DRY_RUN="${DRY_RUN:-0}"
  CONFIG_VERBOSE="${VERBOSE:-0}"

  export VERBOSE="${CONFIG_VERBOSE}"

  output::debug "Loaded config: ORG=$CONFIG_ORG"
  return 0
}

# Get teams from config
config::get_teams() {
  local config_file="$1"

  if [[ ! -f "$config_file" ]]; then
    output::error "Config file not found: $config_file"
    return 1
  fi

  jq -r '.teams[]' "$config_file"
}

# Get projects from config
config::get_projects() {
  local config_file="$1"

  if [[ ! -f "$config_file" ]]; then
    output::error "Config file not found: $config_file"
    return 1
  fi

  jq -r '.projects[] | @json' "$config_file"
}

# Get repos for a specific project
config::get_project_repos() {
  local config_file="$1"
  local project_name="$2"

  if [[ ! -f "$config_file" ]]; then
    output::error "Config file not found: $config_file"
    return 1
  fi

  jq -r ".projects[] | select(.name==\"$project_name\") | .repos[] | @json" "$config_file"
}

# Get all repos across all projects
config::get_all_repos() {
  local config_file="$1"

  if [[ ! -f "$config_file" ]]; then
    output::error "Config file not found: $config_file"
    return 1
  fi

  jq -r '.projects[] as $project | $project.repos[] | {project: $project.name, repo: .name, team: .team, permission: .permission} | @json' "$config_file"
}

# Get organization name
config::get_org() {
  echo "$CONFIG_ORG"
}

# Check if dry-run mode is enabled
config::is_dry_run() {
  [[ "${CONFIG_DRY_RUN}" == "1" ]]
}

# Check if verbose mode is enabled
config::is_verbose() {
  [[ "${CONFIG_VERBOSE}" == "1" ]]
}
