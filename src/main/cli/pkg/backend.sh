#!/bin/bash
# Backend router
# Routes operations to GitHub or Gitea backends based on configuration

# Source utilities
_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=internal/output.sh
source "${_PKG_DIR}/../internal/output.sh"
# shellcheck source=pkg/config.sh
source "${_PKG_DIR}/config.sh"
# shellcheck source=pkg/github.sh
source "${_PKG_DIR}/github.sh"
# shellcheck source=pkg/gitea.sh
source "${_PKG_DIR}/gitea.sh"

# Create team (routes to correct backend)
backend::create_team() {
  local org="$1"
  local team="$2"
  local dry_run="${3:-0}"

  if config::is_gitea; then
    gitea::create_team "$org" "$team" "$dry_run"
  else
    github::create_team "$org" "$team" "$dry_run"
  fi
}

# Create repository (routes to correct backend)
backend::create_repo() {
  local org="$1"
  local repo="$2"
  local dry_run="${3:-0}"

  if config::is_gitea; then
    gitea::create_repo "$org" "$repo" "$dry_run"
  else
    github::create_repo "$org" "$repo" "$dry_run"
  fi
}

# Assign team to repository (routes to correct backend)
backend::assign_team() {
  local org="$1"
  local repo="$2"
  local team="$3"
  local permission="$4"
  local dry_run="${5:-0}"

  if config::is_gitea; then
    gitea::assign_team "$org" "$repo" "$team" "$permission" "$dry_run"
  else
    github::assign_team "$org" "$repo" "$team" "$permission" "$dry_run"
  fi
}

# Clone repository (routes to correct backend)
backend::clone_repo() {
  local org="$1"
  local repo="$2"
  local dest="$3"

  if config::is_gitea; then
    gitea::clone_repo "$org" "$repo" "$dest"
  else
    github::clone_repo "$org" "$repo" "$dest"
  fi
}

# Commit and push changes (same for both backends)
backend::commit_and_push() {
  local repo_dir="$1"
  local commit_msg="$2"
  local dry_run="${3:-0}"

  if config::is_gitea; then
    gitea::commit_and_push "$repo_dir" "$commit_msg" "$dry_run"
  else
    github::commit_and_push "$repo_dir" "$commit_msg" "$dry_run"
  fi
}

# Get backend name for display
backend::get_name() {
  if config::is_gitea; then
    echo "Gitea"
  else
    echo "GitHub"
  fi
}
