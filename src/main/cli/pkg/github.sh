#!/bin/bash
# GitHub API interactions
# Handles GitHub CLI operations for teams, repos, and permissions

# Source utilities
_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=internal/output.sh
source "${_PKG_DIR}/../internal/output.sh"
# shellcheck source=pkg/config.sh
source "${_PKG_DIR}/config.sh"

# Create GitHub team
github::create_team() {
  local org="$1"
  local team="$2"
  local dry_run="${3:-0}"

  if [[ "$dry_run" == "1" ]]; then
    output::dry_run "Would create team: $team"
    return 0
  fi

  # Check if team already exists
  if gh api "/orgs/$org/teams/$team" >/dev/null 2>&1; then
    output::info "Team already exists: $team"
    return 0
  fi

  output::info "Creating team: $team"
  if gh api -X POST "/orgs/$org/teams" -f name="$team" -f privacy="closed" >/dev/null 2>&1; then
    output::success "Team created: $team"
    return 0
  else
    output::error "Failed to create team: $team"
    return 1
  fi
}

# Create GitHub repository
github::create_repo() {
  local org="$1"
  local repo="$2"
  local dry_run="${3:-0}"

  if [[ "$dry_run" == "1" ]]; then
    output::dry_run "Would create repository: $repo"
    return 0
  fi

  # Check if repo already exists
  if gh repo view "$org/$repo" >/dev/null 2>&1; then
    output::info "Repository already exists: $repo"
    return 0
  fi

  output::info "Creating repository: $repo"
  if gh repo create "$org/$repo" --private --confirm >/dev/null 2>&1; then
    output::success "Repository created: $repo"
    sleep 1  # Wait for API propagation
    return 0
  else
    output::error "Failed to create repository: $repo"
    return 1
  fi
}

# Assign team to repository
github::assign_team() {
  local org="$1"
  local repo="$2"
  local team="$3"
  local permission="$4"
  local dry_run="${5:-0}"

  if [[ "$dry_run" == "1" ]]; then
    output::dry_run "Would assign team '$team' to '$repo' with '$permission' permission"
    return 0
  fi

  output::info "Assigning team '$team' to '$repo' with '$permission' permission"
  if gh api -X PUT "/orgs/$org/teams/$team/repos/$org/$repo" -f permission="$permission" >/dev/null 2>&1; then
    output::success "Team assigned: $team -> $repo ($permission)"
    return 0
  else
    output::error "Failed to assign team: $team -> $repo"
    return 1
  fi
}

# Clone repository to temporary directory
github::clone_repo() {
  local org="$1"
  local repo="$2"
  local dest="$3"

  output::debug "Cloning repository: $org/$repo to $dest"

  if gh repo clone "$org/$repo" "$dest" >/dev/null 2>&1; then
    output::debug "Repository cloned successfully"
    return 0
  else
    output::error "Failed to clone repository: $org/$repo"
    return 1
  fi
}

# Commit and push changes to repository
github::commit_and_push() {
  local repo_dir="$1"
  local commit_msg="$2"
  local dry_run="${3:-0}"

  if [[ "$dry_run" == "1" ]]; then
    output::dry_run "Would commit and push: $commit_msg"
    return 0
  fi

  cd "$repo_dir" || return 1

  # Check if there are changes
  if ! git diff --quiet || ! git diff --cached --quiet; then
    git add .
    git commit -m "$commit_msg" >/dev/null 2>&1
    git push >/dev/null 2>&1
    output::success "Changes committed and pushed"
    return 0
  else
    output::debug "No changes to commit"
    return 0
  fi
}

# Get GitHub account type (Organization or User)
github::get_account_type() {
  local org="$1"

  if gh api "/orgs/$org" >/dev/null 2>&1; then
    echo "Organization"
  elif gh api "/users/$org" >/dev/null 2>&1; then
    echo "User"
  else
    echo "Unknown"
  fi
}
