#!/bin/bash
# Gitea API interactions
# Handles tea CLI operations for teams, repos, and permissions

# Source utilities
_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=internal/output.sh
source "${_PKG_DIR}/../internal/output.sh"
# shellcheck source=pkg/config.sh
source "${_PKG_DIR}/config.sh"

# Create Gitea organization (if using org, not personal)
gitea::ensure_org() {
  local org="$1"
  local dry_run="${2:-0}"

  if [[ "$dry_run" == "1" ]]; then
    output::dry_run "Would verify organization: $org"
    return 0
  fi

  # Check if org exists (tea doesn't have direct org check)
  # We'll try to list repos and catch error
  if tea repos list --organization "$org" >/dev/null 2>&1; then
    output::debug "Organization exists: $org"
    return 0
  else
    output::warning "Organization may not exist or you don't have access: $org"
    output::info "Create organization via Gitea web UI: Site Admin > Organizations"
    return 1
  fi
}

# Create Gitea team
gitea::create_team() {
  local org="$1"
  local team="$2"
  local dry_run="${3:-0}"

  if [[ "$dry_run" == "1" ]]; then
    output::dry_run "Would create team: $team"
    return 0
  fi

  # Check if team already exists
  if tea teams list --organization "$org" 2>/dev/null | grep -q "^${team}$"; then
    output::info "Team already exists: $team"
    return 0
  fi

  output::info "Creating team: $team"
  # tea teams create --org ORG --name NAME --description DESC [--permission read|write|admin]
  if tea teams create --organization "$org" --name "$team" >/dev/null 2>&1; then
    output::success "Team created: $team"
    return 0
  else
    output::error "Failed to create team: $team"
    return 1
  fi
}

# Create Gitea repository
gitea::create_repo() {
  local org="$1"
  local repo="$2"
  local dry_run="${3:-0}"

  if [[ "$dry_run" == "1" ]]; then
    output::dry_run "Would create repository: $repo"
    return 0
  fi

  # Check if repo already exists
  if tea repos list --organization "$org" 2>/dev/null | grep -q "^${org}/${repo}$"; then
    output::info "Repository already exists: $repo"
    return 0
  fi

  output::info "Creating repository: $repo"
  # tea repos create --name NAME --owner ORG --private
  if tea repos create --name "$repo" --owner "$org" --private >/dev/null 2>&1; then
    output::success "Repository created: $repo"
    sleep 1  # Wait for API propagation
    return 0
  else
    output::error "Failed to create repository: $repo"
    return 1
  fi
}

# Assign team to repository
gitea::assign_team() {
  local org="$1"
  local repo="$2"
  local team="$3"
  local permission="$4"
  local dry_run="${5:-0}"

  if [[ "$dry_run" == "1" ]]; then
    output::dry_run "Would assign team '$team' to '$repo' with '$permission' permission"
    return 0
  fi

  # Convert GitHub permissions to Gitea permissions
  # GitHub: pull, push, triage, maintain, admin
  # Gitea: read, write, admin
  local gitea_permission
  case "$permission" in
    pull)
      gitea_permission="read"
      ;;
    push|triage|maintain)
      gitea_permission="write"
      ;;
    admin)
      gitea_permission="admin"
      ;;
    *)
      output::warning "Unknown permission: $permission, defaulting to 'write'"
      gitea_permission="write"
      ;;
  esac

  output::info "Assigning team '$team' to '$repo' with '$gitea_permission' permission"
  # tea repos add-team --repo OWNER/NAME --team TEAM --permission PERM
  if tea repos add-team --repo "${org}/${repo}" --team "$team" --permission "$gitea_permission" >/dev/null 2>&1; then
    output::success "Team assigned: $team -> $repo ($gitea_permission)"
    return 0
  else
    output::error "Failed to assign team: $team -> $repo"
    return 1
  fi
}

# Clone repository to temporary directory
gitea::clone_repo() {
  local org="$1"
  local repo="$2"
  local dest="$3"

  output::debug "Cloning repository: $org/$repo to $dest"

  # Get Gitea instance URL from tea config
  local gitea_url
  gitea_url=$(tea login list 2>/dev/null | grep '^\*' | awk '{print $2}')

  if [[ -z "$gitea_url" ]]; then
    output::error "No active tea login found. Run: tea login add"
    return 1
  fi

  # Clone using git with Gitea URL
  if git clone "${gitea_url}/${org}/${repo}.git" "$dest" >/dev/null 2>&1; then
    output::debug "Repository cloned successfully"
    return 0
  else
    output::error "Failed to clone repository: $org/$repo"
    return 1
  fi
}

# Commit and push changes to repository
gitea::commit_and_push() {
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

# Get Gitea instance URL
gitea::get_url() {
  tea login list 2>/dev/null | grep '^\*' | awk '{print $2}'
}

# Check Gitea authentication
gitea::check_auth() {
  if tea login list >/dev/null 2>&1; then
    local active_login
    active_login=$(tea login list 2>/dev/null | grep '^\*')
    if [[ -n "$active_login" ]]; then
      return 0
    fi
  fi
  return 1
}
