#!/bin/bash
# Output utilities for CLI
# Provides colored output and formatting functions

# Color codes (use declare -g to avoid readonly conflicts)
if [[ -z "${OUTPUT_SH_LOADED:-}" ]]; then
  declare -g RED='\033[0;31m'
  declare -g GREEN='\033[0;32m'
  declare -g YELLOW='\033[1;33m'
  declare -g BLUE='\033[0;34m'
  declare -g CYAN='\033[0;36m'
  declare -g BOLD='\033[1m'
  declare -g NC='\033[0m' # No Color
  OUTPUT_SH_LOADED=1
fi

# Output functions
output::info() {
  echo -e "${BLUE}ℹ${NC} $*"
}

output::success() {
  echo -e "${GREEN}✓${NC} $*"
}

output::warning() {
  echo -e "${YELLOW}⚠${NC} $*"
}

output::error() {
  echo -e "${RED}✗${NC} $*" >&2
}

output::header() {
  echo -e "${BOLD}${CYAN}$*${NC}"
}

output::debug() {
  if [[ "${VERBOSE:-0}" == "1" ]]; then
    echo -e "${CYAN}[DEBUG]${NC} $*"
  fi
}

output::dry_run() {
  echo -e "${YELLOW}[DRY RUN]${NC} $*"
}

# Check if output is a TTY (for disabling colors in pipes)
output::is_tty() {
  [[ -t 1 ]]
}

# Disable colors if not a TTY
if ! output::is_tty; then
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  CYAN=""
  BOLD=""
  NC=""
fi
