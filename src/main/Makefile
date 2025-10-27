# ============================================================================
# GitHub Organization Project Management Automation
# ============================================================================
# This Makefile automates the creation and configuration of GitHub teams,
# repositories, and standard files across multiple projects.
#
# Usage:
#   make all              - Run all targets (full setup)
#   make teams            - Create teams only
#   make repos            - Create repositories only
#   make readmes          - Add README files only
#   make workflows        - Add GitHub Actions workflows only
#   make codeowners       - Add CODEOWNERS files only
#   make clean            - Clean up temporary files
#   make all DRY_RUN=1    - Preview changes without executing
#
# Prerequisites:
#   - gh CLI (GitHub CLI)
#   - jq (JSON processor)
#   - git
#   - .env file with ORG variable set
#   - project-config.json with teams/projects configuration
#   - Template files in templates/ directory
# ============================================================================

# Determine project root directory (two levels up from Makefile location)
ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))/../..

# Load environment variables from .env file in project root
# -include: don't error if .env doesn't exist (checked in prerequisites)
# export: make all variables available to shell commands
-include $(ROOT_DIR)/.env
export

# ============================================================================
# Configuration Variables
# ============================================================================

# Use bash as the shell for all commands (required for complex if/fi structures)
SHELL := /bin/bash

# Use .ONESHELL to execute all recipe lines in a single shell invocation
.ONESHELL:

# Path to JSON configuration file containing teams and projects (in project root)
CONFIG := $(ROOT_DIR)/project-config.json

# Default git branch (not currently used, reserved for future features)
DEFAULT_BRANCH := main

# Temporary directory for cloning repositories (in project root)
TMP_DIR := $(ROOT_DIR)/.tmp-repos

# Dry-run mode: Set to 1 to preview actions without executing
# Override with: make all DRY_RUN=1
DRY_RUN ?= 0

# Verbose mode: Set to 1 for detailed output (reserved for future use)
VERBOSE ?= 0

# ============================================================================
# Color Codes for Terminal Output
# ============================================================================

RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# ============================================================================
# Phony Targets (not actual files)
# ============================================================================

.PHONY: all check-prereqs teams repos readmes workflows codeowners clean

# ============================================================================
# Main Target: Run All Setup Steps
# ============================================================================

all: check-prereqs teams repos readmes workflows codeowners

# ============================================================================
# Target: check-prereqs
# ============================================================================
# Validates that all required tools, files, and configurations are present
# before running any automation tasks.
#
# Checks:
#   1. .env file exists
#   2. ORG variable is set in .env
#   3. Required CLI tools are installed (gh, jq, git)
#   4. project-config.json exists
#   5. GitHub authentication is active
#   6. All template files exist
#
# Exits with error if any prerequisite is missing.
# ============================================================================

check-prereqs:
	@echo "$(BLUE)🔍 Checking prerequisites...$(NC)"

	# Check .env file exists
	@test -f $(ROOT_DIR)/.env || { echo "$(RED)❌ .env file not found. Copy .env.example to .env and configure it.$(NC)"; exit 1; }

	# Check ORG variable is set (loaded from .env)
	@test -n "$(ORG)" || { echo "$(RED)❌ ORG variable not set in .env file$(NC)"; exit 1; }

	# Check GitHub CLI is installed
	@command -v gh >/dev/null 2>&1 || { echo "$(RED)❌ gh CLI not installed. Install from https://cli.github.com$(NC)"; exit 1; }

	# Check jq (JSON processor) is installed
	@command -v jq >/dev/null 2>&1 || { echo "$(RED)❌ jq not installed. Install with: apt-get install jq$(NC)"; exit 1; }

	# Check git is installed
	@command -v git >/dev/null 2>&1 || { echo "$(RED)❌ git not installed$(NC)"; exit 1; }

	# Check configuration file exists
	@test -f $(CONFIG) || { echo "$(RED)❌ $(CONFIG) not found$(NC)"; exit 1; }

	# Check GitHub authentication status
	@gh auth status >/dev/null 2>&1 || { echo "$(RED)❌ Not authenticated with GitHub. Run: gh auth login$(NC)"; exit 1; }

	# Check all required template files exist
	@for ROLE in frontend backend infra; do \
		test -f templates/README-$$ROLE.md || { echo "$(RED)❌ templates/README-$$ROLE.md not found$(NC)"; exit 1; }; \
		test -f templates/workflow-$$ROLE.yml || { echo "$(RED)❌ templates/workflow-$$ROLE.yml not found$(NC)"; exit 1; }; \
	done
	@test -f templates/CODEOWNERS || { echo "$(RED)❌ templates/CODEOWNERS not found$(NC)"; exit 1; }

	@echo "$(GREEN)✅ All prerequisites met (ORG: $(ORG))$(NC)"

# ============================================================================
# Target: teams
# ============================================================================
# Creates GitHub teams as defined in project-config.json.
#
# Process:
#   1. Read team names from .teams[] array in config
#   2. For each team:
#      - Check if team already exists (idempotent)
#      - Create team with 'closed' privacy setting
#      - Handle errors gracefully
#
# API: POST /orgs/{org}/teams
# Privacy: closed (only org members can see)
#
# Idempotent: Yes - skips existing teams
# Dry-run support: Yes
# ============================================================================

teams:
	@echo "$(BLUE)🔧 Creating teams...$(NC)"

	# set -e: exit on error
	# jq -r '.teams[]': extract team names from JSON array
	@set -e; jq -r '.teams[]' $(CONFIG) | while read TEAM; do \
		if [ "$(DRY_RUN)" = "1" ]; then \
			# Dry-run mode: just preview the action
			echo "$(YELLOW)[DRY RUN]$(NC) Would create team: $$TEAM"; \
		else \
			# Check if team already exists (idempotency check)
			# gh api /orgs/ORG/teams/TEAM returns 200 if exists, 404 if not
			if gh api /orgs/$(ORG)/teams/$$TEAM 2>/dev/null | jq -e . >/dev/null 2>&1; then \
				echo "$(YELLOW)⏭️  Team '$$TEAM' already exists, skipping...$(NC)"; \
			else \
				# Create new team with closed privacy
				echo "$(GREEN)✨ Creating team: $$TEAM$(NC)"; \
				gh api -X POST /orgs/$(ORG)/teams -f name="$$TEAM" -f privacy="closed" || { echo "$(RED)❌ Failed to create team $$TEAM$(NC)"; exit 1; }; \
			fi; \
		fi; \
	done
	@echo "$(GREEN)✅ Teams creation complete$(NC)"

# ============================================================================
# Target: repos
# ============================================================================
# Creates GitHub repositories and assigns teams with permissions.
#
# Process:
#   1. Read projects from .projects[] array
#   2. For each project and its repos:
#      - Generate repo name: project-{PROJECT_NAME}-{REPO_NAME}
#      - Check if repo exists (idempotent)
#      - Create private repository
#      - Assign team with specified permission level
#
# Repository naming: project-{project_name}-{repo_role}
# Example: project-alpha-frontend, project-beta-backend
#
# API Calls:
#   - gh repo create: Creates repository
#   - PUT /orgs/{org}/teams/{team}/repos/{org}/{repo}: Assigns team
#
# Permissions: pull, push, admin, maintain, triage
#
# Idempotent: Yes - skips existing repos, re-assigns team permissions
# Dry-run support: Yes
# ============================================================================

repos:
	@echo "$(BLUE)📁 Creating repositories and assigning teams...$(NC)"

	# jq -c '.projects[]': extract projects as compact JSON objects
	@set -e; jq -c '.projects[]' $(CONFIG) | while read PROJECT; do \
		# Extract project name from JSON object
		PROJECT_NAME=$$(echo $$PROJECT | jq -r '.name'); \
		echo "$(BLUE)📦 Project: $$PROJECT_NAME$(NC)"; \

		# Process each repository in this project
		echo $$PROJECT | jq -c '.repos[]' | while read REPO; do \
			# Build repository name: project-{PROJECT}-{ROLE}
			REPO_NAME=project-$$PROJECT_NAME-$$(echo $$REPO | jq -r '.name'); \
			TEAM_NAME=$$(echo $$REPO | jq -r '.team'); \
			PERMISSION=$$(echo $$REPO | jq -r '.permission'); \

			if [ "$(DRY_RUN)" = "1" ]; then \
				# Dry-run mode: preview actions
				echo "$(YELLOW)[DRY RUN]$(NC) Would create repo: $(ORG)/$$REPO_NAME"; \
				echo "$(YELLOW)[DRY RUN]$(NC) Would assign team '$$TEAM_NAME' with '$$PERMISSION' permission"; \
			else \
				# Check if repository already exists
				if gh repo view $(ORG)/$$REPO_NAME >/dev/null 2>&1; then \
					echo "$(YELLOW)⏭️  Repository '$$REPO_NAME' already exists, skipping creation...$(NC)"; \
				else \
					# Create new private repository
					echo "$(GREEN)✨ Creating repository: $$REPO_NAME$(NC)"; \
					gh repo create $(ORG)/$$REPO_NAME --private --confirm || { echo "$(RED)❌ Failed to create repo $$REPO_NAME$(NC)"; exit 1; }; \
					# Wait for GitHub API to propagate the new repo
					sleep 1; \
				fi; \

				# Assign team to repository with specified permission
				# This runs even if repo exists (allows updating permissions)
				echo "$(GREEN)🔗 Assigning team '$$TEAM_NAME' with '$$PERMISSION' permission$(NC)"; \
				gh api -X PUT /orgs/$(ORG)/teams/$$TEAM_NAME/repos/$(ORG)/$$REPO_NAME -f permission="$$PERMISSION" || { echo "$(RED)❌ Failed to assign team $$TEAM_NAME to repo $$REPO_NAME$(NC)"; exit 1; }; \
			fi; \
		done; \
	done
	@echo "$(GREEN)✅ Repositories creation complete$(NC)"

# ============================================================================
# Target: readmes
# ============================================================================
# Adds role-specific README templates to each repository.
#
# Process:
#   1. For each repository in config:
#      - Determine role from repo name (frontend, backend, infra)
#      - Clone repository to temporary directory
#      - Copy appropriate README template
#      - Commit and push changes
#      - Clean up temporary clone
#
# Template mapping: templates/README-{role}.md → README.md
#
# Commit message: "docs: add README template for {role}"
#
# Idempotent: Sort of - git commit/push fails silently if no changes
# Dry-run support: Yes
# ============================================================================

readmes:
	@echo "$(BLUE)📝 Adding README templates...$(NC)"

	# Create temporary directory for clones
	@mkdir -p $(TMP_DIR)

	@set -e; jq -c '.projects[]' $(CONFIG) | while read PROJECT; do \
		PROJECT_NAME=$$(echo $$PROJECT | jq -r '.name'); \
		echo $$PROJECT | jq -c '.repos[]' | while read REPO; do \
			REPO_NAME=project-$$PROJECT_NAME-$$(echo $$REPO | jq -r '.name'); \
			# Extract role from repo name (used to select template)
			ROLE=$$(echo $$REPO | jq -r '.name'); \

			if [ "$(DRY_RUN)" = "1" ]; then \
				echo "$(YELLOW)[DRY RUN]$(NC) Would add README-$$ROLE.md to $(ORG)/$$REPO_NAME"; \
			else \
				echo "$(GREEN)📄 Adding README to $$REPO_NAME (role: $$ROLE)$(NC)"; \

				# Set up temporary clone directory
				CLONE_DIR=$(TMP_DIR)/$$REPO_NAME; \
				rm -rf $$CLONE_DIR; \

				# Clone repository (using SSH)
				git clone git@github.com:$(ORG)/$$REPO_NAME.git $$CLONE_DIR 2>/dev/null || { echo "$(RED)❌ Failed to clone $$REPO_NAME$(NC)"; exit 1; }; \

				# Copy role-specific README template
				cp templates/README-$$ROLE.md $$CLONE_DIR/README.md || { echo "$(RED)❌ Template README-$$ROLE.md not found$(NC)"; exit 1; }; \

				# Commit and push (fails silently if file already exists)
				cd $$CLONE_DIR && \
					git add README.md && \
					git commit -m "docs: add README template for $$ROLE" && \
					git push || { echo "$(YELLOW)⏭️  No changes or already exists$(NC)"; }; \

				# Return to previous directory and clean up
				cd - >/dev/null; \
				rm -rf $$CLONE_DIR; \
			fi; \
		done; \
	done
	@echo "$(GREEN)✅ README templates added$(NC)"

# ============================================================================
# Target: workflows
# ============================================================================
# Adds role-specific GitHub Actions CI/CD workflows to each repository.
#
# Process:
#   1. For each repository in config:
#      - Determine role from repo name
#      - Clone repository to temporary directory
#      - Create .github/workflows directory
#      - Copy appropriate workflow template as ci.yml
#      - Commit and push changes
#      - Clean up temporary clone
#
# Template mapping: templates/workflow-{role}.yml → .github/workflows/ci.yml
#
# Commit message: "ci: add GitHub Actions workflow for {role}"
#
# Idempotent: Sort of - git commit/push fails silently if no changes
# Dry-run support: Yes
# ============================================================================

workflows:
	@echo "$(BLUE)⚙️ Adding GitHub Actions workflows...$(NC)"

	# Create temporary directory for clones
	@mkdir -p $(TMP_DIR)

	@set -e; jq -c '.projects[]' $(CONFIG) | while read PROJECT; do \
		PROJECT_NAME=$$(echo $$PROJECT | jq -r '.name'); \
		echo $$PROJECT | jq -c '.repos[]' | while read REPO; do \
			REPO_NAME=project-$$PROJECT_NAME-$$(echo $$REPO | jq -r '.name'); \
			# Extract role from repo name (used to select template)
			ROLE=$$(echo $$REPO | jq -r '.name'); \

			if [ "$(DRY_RUN)" = "1" ]; then \
				echo "$(YELLOW)[DRY RUN]$(NC) Would add workflow-$$ROLE.yml to $(ORG)/$$REPO_NAME"; \
			else \
				echo "$(GREEN)⚙️  Adding workflow to $$REPO_NAME (role: $$ROLE)$(NC)"; \

				# Set up temporary clone directory
				CLONE_DIR=$(TMP_DIR)/$$REPO_NAME; \
				rm -rf $$CLONE_DIR; \

				# Clone repository (using SSH)
				git clone git@github.com:$(ORG)/$$REPO_NAME.git $$CLONE_DIR 2>/dev/null || { echo "$(RED)❌ Failed to clone $$REPO_NAME$(NC)"; exit 1; }; \

				# Create .github/workflows directory structure
				mkdir -p $$CLONE_DIR/.github/workflows; \

				# Copy role-specific workflow template
				cp templates/workflow-$$ROLE.yml $$CLONE_DIR/.github/workflows/ci.yml || { echo "$(RED)❌ Template workflow-$$ROLE.yml not found$(NC)"; exit 1; }; \

				# Commit and push (fails silently if file already exists)
				cd $$CLONE_DIR && \
					git add .github/workflows/ci.yml && \
					git commit -m "ci: add GitHub Actions workflow for $$ROLE" && \
					git push || { echo "$(YELLOW)⏭️  No changes or already exists$(NC)"; }; \

				# Return to previous directory and clean up
				cd - >/dev/null; \
				rm -rf $$CLONE_DIR; \
			fi; \
		done; \
	done
	@echo "$(GREEN)✅ Workflows added$(NC)"

# ============================================================================
# Target: codeowners
# ============================================================================
# Adds CODEOWNERS file to each repository for automated code review.
#
# Process:
#   1. For each repository in config:
#      - Clone repository to temporary directory
#      - Create .github directory
#      - Copy CODEOWNERS template
#      - Commit and push changes
#      - Clean up temporary clone
#
# Template mapping: templates/CODEOWNERS → .github/CODEOWNERS
#
# CODEOWNERS enables automatic reviewer assignment for pull requests.
# GitHub uses this file to determine who should review code changes.
#
# Commit message: "chore: add CODEOWNERS file"
#
# Idempotent: Sort of - git commit/push fails silently if no changes
# Dry-run support: Yes
# ============================================================================

codeowners:
	@echo "$(BLUE)🧾 Adding CODEOWNERS...$(NC)"

	# Create temporary directory for clones
	@mkdir -p $(TMP_DIR)

	@set -e; jq -c '.projects[]' $(CONFIG) | while read PROJECT; do \
		PROJECT_NAME=$$(echo $$PROJECT | jq -r '.name'); \
		echo $$PROJECT | jq -c '.repos[]' | while read REPO; do \
			REPO_NAME=project-$$PROJECT_NAME-$$(echo $$REPO | jq -r '.name'); \

			if [ "$(DRY_RUN)" = "1" ]; then \
				echo "$(YELLOW)[DRY RUN]$(NC) Would add CODEOWNERS to $(ORG)/$$REPO_NAME"; \
			else \
				echo "$(GREEN)👥 Adding CODEOWNERS to $$REPO_NAME$(NC)"; \

				# Set up temporary clone directory
				CLONE_DIR=$(TMP_DIR)/$$REPO_NAME; \
				rm -rf $$CLONE_DIR; \

				# Clone repository (using SSH)
				git clone git@github.com:$(ORG)/$$REPO_NAME.git $$CLONE_DIR 2>/dev/null || { echo "$(RED)❌ Failed to clone $$REPO_NAME$(NC)"; exit 1; }; \

				# Create .github directory
				mkdir -p $$CLONE_DIR/.github; \

				# Copy CODEOWNERS template (same file for all repos)
				cp templates/CODEOWNERS $$CLONE_DIR/.github/CODEOWNERS || { echo "$(RED)❌ Template CODEOWNERS not found$(NC)"; exit 1; }; \

				# Commit and push (fails silently if file already exists)
				cd $$CLONE_DIR && \
					git add .github/CODEOWNERS && \
					git commit -m "chore: add CODEOWNERS file" && \
					git push || { echo "$(YELLOW)⏭️  No changes or already exists$(NC)"; }; \

				# Return to previous directory and clean up
				cd - >/dev/null; \
				rm -rf $$CLONE_DIR; \
			fi; \
		done; \
	done
	@echo "$(GREEN)✅ CODEOWNERS files added$(NC)"

# ============================================================================
# Target: clean
# ============================================================================
# Removes temporary directories created during file addition operations.
#
# Cleans up:
#   - .tmp-repos/ directory and all its contents
#
# Safe to run at any time. Does not affect GitHub resources.
# ============================================================================

clean:
	@echo "$(BLUE)🧹 Cleaning up temporary files...$(NC)"
	@rm -rf $(TMP_DIR)
	@echo "$(GREEN)✅ Cleanup complete$(NC)"
