# Local Development Setup

**Version:** 1.0.0
**Last Updated:** 2025-10-27

## TL;DR

**Quick setup**: Clone repo → Install prerequisites (gh/tea, jq, git) → Configure .env → Run `./src/main/cli/gh-org check`. **Two backends**: GitHub (cloud, needs auth) or Gitea (local Docker, 5 min setup). **For GitHub**: `gh auth login`. **For Gitea**: Docker + tea CLI. **Testing**: Run test suite with `make -C src/test all`. **Common issues**: Authentication, org permissions, missing tools.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [GitHub Setup](#github-setup)
- [Gitea Local Setup](#gitea-local-setup)
- [Configuration](#configuration)
- [Verification](#verification)
- [Running Tests](#running-tests)
- [Development Workflow](#development-workflow)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## Overview

This guide walks you through setting up a local development environment for the Git Platform Organization Automation tool.

**What you'll set up:**
- Development tools and dependencies
- Backend platform (GitHub or Gitea)
- Project configuration
- Test environment

**Time required:**
- GitHub setup: 10-15 minutes
- Gitea local setup: 20-30 minutes

---

## Prerequisites

### System Requirements

**Operating System:**
- Linux (Ubuntu 20.04+, Debian 11+, etc.)
- macOS (10.15+)
- Windows (WSL2 Ubuntu 20.04+)

**Resources:**
- CPU: 2+ cores
- RAM: 4GB minimum, 8GB recommended
- Disk: 10GB free space
- Network: Internet access for GitHub, Docker for Gitea

### Required Tools

**Core tools (all setups):**

| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| **Git** | 2.0+ | Version control | `apt install git` |
| **jq** | 1.6+ | JSON processing | `apt install jq` |
| **Bash** | 4.0+ | Shell scripting | Pre-installed |
| **Make** | 4.0+ | Build automation | `apt install make` |

**Backend-specific tools:**

| Backend | Tool | Version | Purpose | Install |
|---------|------|---------|---------|---------|
| **GitHub** | gh CLI | 2.0+ | GitHub API | https://cli.github.com |
| **Gitea** | tea CLI | 0.9+ | Gitea API | https://gitea.com/gitea/tea |
| **Gitea** | Docker | 20+ | Run Gitea | https://docker.com |

### Check Installed Tools

```bash
# Check versions
git --version           # Should be 2.0+
jq --version           # Should be 1.6+
make --version         # Should be 4.0+
bash --version         # Should be 4.0+

# Check GitHub CLI (if using GitHub)
gh --version           # Should be 2.0+

# Check Gitea tools (if using Gitea)
tea --version          # Should be 0.9+
docker --version       # Should be 20.0+
```

---

## Quick Start

### 1. Clone Repository

```bash
# Clone the repository
git clone https://github.com/phdsystems/project-management-automation.git
cd project-management-automation

# Verify structure
ls -la
# Should see: src/, doc/, .env.example, project-config.json, etc.
```

### 2. Install Prerequisites

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install git jq make bash curl wget

# For GitHub backend
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# For Gitea backend (Docker)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

**macOS:**
```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install git jq make bash

# For GitHub backend
brew install gh

# For Gitea backend
brew install docker tea
```

### 3. Choose Backend

**Option A: GitHub (Cloud)**
- ✅ Quick setup
- ✅ No local infrastructure
- ⚠️ Requires GitHub organization
- ⚠️ May incur costs

**Option B: Gitea (Local)**
- ✅ Free, no costs
- ✅ Full control
- ✅ Test without real org
- ⚠️ Requires Docker

Choose your path below.

---

## GitHub Setup

### Step 1: Install GitHub CLI

```bash
# Ubuntu/Debian
sudo apt install gh

# macOS
brew install gh

# Verify
gh --version
```

### Step 2: Authenticate

```bash
# Login to GitHub
gh auth login

# Follow prompts:
# - What account? GitHub.com
# - Protocol? HTTPS
# - Authenticate? Login with browser
# - Complete browser authentication

# Verify
gh auth status
# Should show: ✓ Logged in to github.com
```

### Step 3: Verify Organization Access

```bash
# List organizations you have access to
gh api user/orgs --jq '.[].login'

# Check if you have admin access to your org
gh api /orgs/YOUR-ORG-NAME/memberships/YOUR-USERNAME --jq '.role'
# Should show: admin or owner

# If not admin, request access from organization owner
```

### Step 4: Configure Environment

```bash
# Copy example config
cp .env.example .env

# Edit .env
nano .env
```

**Set these values:**
```bash
# Your GitHub organization name
ORG=your-org-name

# Use GitHub backend (default)
BACKEND=github
```

### Step 5: Test Connection

```bash
# Run prerequisites check
./src/main/cli/gh-org check

# Expected output:
# Checking prerequisites...
# ✓ All prerequisites met
```

**Success!** Continue to [Configuration](#configuration).

---

## Gitea Local Setup

### Step 1: Install Docker

**Ubuntu/Debian:**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker --version
docker ps  # Should not show permission error
```

**macOS:**
```bash
# Install Docker Desktop
brew install --cask docker

# Launch Docker Desktop from Applications
# Wait for Docker to start

# Verify
docker --version
docker ps
```

### Step 2: Start Gitea Container

```bash
# Pull and run Gitea
sudo docker run -d \
  --name=gitea \
  -p 3000:3000 \
  -p 2222:22 \
  -v gitea-data:/data \
  gitea/gitea:latest

# Check status
sudo docker ps | grep gitea
# Should show: gitea container running

# Wait for Gitea to start (30 seconds)
sleep 30
```

### Step 3: Configure Gitea

```bash
# Create configuration file
sudo docker exec gitea sh -c "cat > /data/gitea/conf/app.ini << 'EOF'
APP_NAME = Gitea: Git with a cup of tea
RUN_MODE = prod

[database]
DB_TYPE  = sqlite3
PATH     = /data/gitea/gitea.db

[repository]
ROOT = /data/git/repositories

[server]
DOMAIN           = localhost
HTTP_PORT        = 3000
ROOT_URL         = http://localhost:3000/
DISABLE_SSH      = false
SSH_PORT         = 22
LFS_START_SERVER = true

[lfs]
PATH = /data/git/lfs

[service]
REGISTER_EMAIL_CONFIRM            = false
ENABLE_NOTIFY_MAIL                = false
DISABLE_REGISTRATION              = false
REQUIRE_SIGNIN_VIEW               = false
DEFAULT_ALLOW_CREATE_ORGANIZATION = true
DEFAULT_ENABLE_TIMETRACKING       = true
NO_REPLY_ADDRESS                  = noreply.localhost

[session]
PROVIDER = file

[log]
MODE      = console
LEVEL     = info
ROOT_PATH = /data/gitea/log

[security]
INSTALL_LOCK   = true
SECRET_KEY     = changeme-secret-key-123456789
INTERNAL_TOKEN = changeme-internal-token-123456789
EOF
"

# Restart Gitea
sudo docker restart gitea
sleep 10
```

### Step 4: Create Admin User

```bash
# Create admin user
sudo docker exec -u git gitea gitea admin user create \
  --username gitea_admin \
  --password admin123456 \
  --email admin@localhost \
  --admin \
  --must-change-password=false

# Expected output:
# New user 'gitea_admin' has been successfully created!
```

### Step 5: Install tea CLI

**Linux:**
```bash
# Download tea CLI
wget https://dl.gitea.com/tea/0.9.2/tea-0.9.2-linux-amd64 -O tea
chmod +x tea
sudo mv tea /usr/local/bin/

# Verify
tea --version
```

**macOS:**
```bash
# Install via Homebrew
brew install tea

# Verify
tea --version
```

### Step 6: Authenticate with tea CLI

```bash
# Get Gitea container IP
GITEA_IP=$(sudo docker inspect gitea | jq -r '.[0].NetworkSettings.IPAddress')
echo "Gitea IP: $GITEA_IP"

# Create access token
TOKEN=$(curl -s -X POST http://${GITEA_IP}:3000/api/v1/users/gitea_admin/tokens \
  -u gitea_admin:admin123456 \
  -H "Content-Type: application/json" \
  -d '{"name":"cli-token","scopes":["write:organization","write:repository","write:user"]}' \
  | jq -r '.sha1')

echo "Token: $TOKEN"

# Login with tea CLI
tea login add \
  --name localhost \
  --url http://${GITEA_IP}:3000 \
  --token $TOKEN

# Set as default
tea login default localhost

# Verify
tea login list
# Should show: localhost with DEFAULT = true
```

### Step 7: Create Test Organization

```bash
# Create organization via API
curl -s -X POST http://${GITEA_IP}:3000/api/v1/orgs \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test-org","description":"Test organization for automation","visibility":"public"}' \
  | jq '{name: .username, id: .id}'

# Expected output:
# {
#   "name": "test-org",
#   "id": 2
# }
```

### Step 8: Configure Environment

```bash
# Copy example config
cp .env.example .env

# Edit .env
nano .env
```

**Set these values:**
```bash
# Your Gitea organization name
ORG=test-org

# Use Gitea backend
BACKEND=gitea
```

### Step 9: Configure Git Credentials

```bash
# Get Gitea IP (if not already set)
GITEA_IP=$(sudo docker inspect gitea | jq -r '.[0].NetworkSettings.IPAddress')

# Store credentials for git operations
git config --global credential.helper store
echo "http://gitea_admin:${TOKEN}@${GITEA_IP}:3000" > ~/.git-credentials
```

### Step 10: Test Connection

```bash
# Run prerequisites check
./src/main/cli/gh-org check

# Expected output:
# Checking prerequisites...
# ✓ All prerequisites met
```

**Success!** Continue to [Configuration](#configuration).

---

## Configuration

### Project Configuration File

Edit `project-config.json` to define your teams and repositories:

```bash
# Edit configuration
nano project-config.json
```

**Example configuration:**
```json
{
  "teams": [
    "frontend-team",
    "backend-team",
    "infra-team"
  ],
  "projects": [
    {
      "name": "alpha",
      "repos": [
        {
          "name": "frontend",
          "team": "frontend-team",
          "permission": "push"
        },
        {
          "name": "backend",
          "team": "backend-team",
          "permission": "push"
        },
        {
          "name": "infra",
          "team": "infra-team",
          "permission": "admin"
        }
      ]
    },
    {
      "name": "beta",
      "repos": [
        {
          "name": "api",
          "team": "backend-team",
          "permission": "push"
        }
      ]
    }
  ]
}
```

**This creates:**
- 3 teams: frontend-team, backend-team, infra-team
- 4 repositories:
  - `project-alpha-frontend` (frontend-team, push)
  - `project-alpha-backend` (backend-team, push)
  - `project-alpha-infra` (infra-team, admin)
  - `project-beta-api` (backend-team, push)

### Validate Configuration

```bash
# Validate JSON syntax
jq empty project-config.json
# No output = valid JSON

# Pretty print to check structure
jq . project-config.json

# Check prerequisites
./src/main/cli/gh-org check
```

---

## Verification

### Test Individual Operations

```bash
# 1. Check prerequisites
./src/main/cli/gh-org check
# ✓ All prerequisites met

# 2. Preview team creation (dry-run)
./src/main/cli/gh-org teams create --dry-run
# [DRY RUN] Would create team: frontend-team
# [DRY RUN] Would create team: backend-team
# [DRY RUN] Would create team: infra-team

# 3. Preview repository creation (dry-run)
./src/main/cli/gh-org repos create --dry-run
# [DRY RUN] Would create repository: project-alpha-frontend
# [DRY RUN] Would assign team 'frontend-team' with 'push' permission
# ...

# 4. Preview complete setup (dry-run)
./src/main/cli/gh-org setup --dry-run
# Shows all operations that would be performed
```

### Run Complete Setup (Creates Real Resources)

```bash
# Run complete automation
./src/main/cli/gh-org setup

# Expected output:
# Running complete GitHub organization setup
# Checking prerequisites...
# ✓ All prerequisites met
#
# Step 1/5: Creating teams
# ℹ Creating team: frontend-team
# ✓ Team created: frontend-team
# ...
#
# Step 2/5: Creating repositories
# ℹ Creating repository: project-alpha-frontend
# ✓ Repository created: project-alpha-frontend
# ...
#
# ✓ Setup completed successfully!
```

### Verify in Web UI

**GitHub:**
```bash
# Open organization in browser
open "https://github.com/orgs/YOUR-ORG-NAME/teams"
# or
xdg-open "https://github.com/orgs/YOUR-ORG-NAME/teams"
```

**Gitea:**
```bash
# Get Gitea URL
GITEA_IP=$(sudo docker inspect gitea | jq -r '.[0].NetworkSettings.IPAddress')
echo "Gitea URL: http://${GITEA_IP}:3000"

# Open in browser (manually)
# Navigate to: http://<GITEA_IP>:3000
# Login: gitea_admin / admin123456
# Check: Organizations → test-org → Teams
```

---

## Running Tests

### Test Suite

```bash
# Run all tests
make -C src/test all

# Run specific test categories
make -C src/test unit          # Unit tests
make -C src/test integration   # Integration tests
make -C src/test validation    # Config validation tests

# View test report
cat src/test/test-report.txt
```

### Manual Testing Workflow

```bash
# 1. Clean state
./src/test/cleanup.sh  # Remove test resources

# 2. Run automation
./src/main/cli/gh-org setup

# 3. Verify results
./src/main/cli/gh-org check

# 4. Test modifications
# Edit project-config.json (add new team/repo)
./src/main/cli/gh-org setup  # Idempotent - only creates new resources

# 5. Clean up
./src/test/cleanup.sh
```

---

## Development Workflow

### Daily Development

```bash
# 1. Pull latest changes
git pull origin main

# 2. Create feature branch
git checkout -b feature/your-feature-name

# 3. Make changes
# Edit files in src/main/cli/

# 4. Test locally
./src/main/cli/gh-org check
./src/main/cli/gh-org teams create --dry-run

# 5. Run test suite
make -C src/test all

# 6. Commit changes
git add src/main/cli/
git commit -m "feat(cli): add new feature"

# 7. Push and create PR
git push origin feature/your-feature-name
gh pr create
```

### Backend Development

**Testing GitHub backend:**
```bash
# Set backend
export BACKEND=github
# or edit .env: BACKEND=github

# Test operations
./src/main/cli/gh-org teams create --dry-run
```

**Testing Gitea backend:**
```bash
# Set backend
export BACKEND=gitea
# or edit .env: BACKEND=gitea

# Test operations
./src/main/cli/gh-org teams create --dry-run
```

### Code Structure

```
src/main/cli/
├── gh-org                  # Main CLI entry point
├── cmd/                    # Command handlers
│   ├── check.sh           # Prerequisites check
│   ├── teams.sh           # Team management
│   ├── repos.sh           # Repository management
│   ├── files.sh           # File templates
│   └── setup.sh           # Complete setup
├── pkg/                    # Core logic
│   ├── backend.sh         # Backend router
│   ├── github.sh          # GitHub implementation
│   ├── gitea.sh           # Gitea implementation
│   ├── config.sh          # Configuration
│   └── templates.sh       # Template engine
└── internal/               # Utilities
    ├── output.sh          # Pretty output
    └── validation.sh      # Prerequisites validation
```

---

## Troubleshooting

### Common Issues

#### Issue: "Not authenticated with GitHub"

**Symptoms:**
```
✗ Not authenticated with GitHub
ℹ Run: gh auth login
```

**Solution:**
```bash
# Login to GitHub
gh auth login

# Verify
gh auth status

# If still failing, refresh token
gh auth refresh -h github.com
```

---

#### Issue: "Not authenticated with Gitea"

**Symptoms:**
```
✗ Not authenticated with Gitea
ℹ Run: tea login add
```

**Solution:**
```bash
# Check tea logins
tea login list

# Should show a login with DEFAULT = true
# If not, set default
tea login default localhost

# Verify
tea login list | grep true
```

---

#### Issue: "Organization not found"

**Symptoms:**
```
✗ Failed to create team: frontend-team
Error: 404 Not Found
```

**Solution:**

**GitHub:**
```bash
# Verify organization exists
gh api /orgs/YOUR-ORG-NAME

# Check your membership
gh api /orgs/YOUR-ORG-NAME/memberships/YOUR-USERNAME

# Must show role: admin or owner
```

**Gitea:**
```bash
# Get Gitea IP
GITEA_IP=$(sudo docker inspect gitea | jq -r '.[0].NetworkSettings.IPAddress')

# Check organization exists
curl -s -H "Authorization: token $TOKEN" \
  "http://${GITEA_IP}:3000/api/v1/orgs/test-org" | jq .

# If missing, create it
curl -s -X POST http://${GITEA_IP}:3000/api/v1/orgs \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test-org","description":"Test org"}'
```

---

#### Issue: "Permission denied" when cloning repos

**Symptoms:**
```
✗ Failed to clone repository: test-org/project-test-frontend
fatal: Authentication failed
```

**Solution:**

**Gitea:**
```bash
# Configure git credentials
GITEA_IP=$(sudo docker inspect gitea | jq -r '.[0].NetworkSettings.IPAddress')
git config --global credential.helper store
echo "http://gitea_admin:${TOKEN}@${GITEA_IP}:3000" > ~/.git-credentials

# Test clone manually
git clone http://${GITEA_IP}:3000/test-org/project-test-frontend.git /tmp/test
```

---

#### Issue: "Docker permission denied"

**Symptoms:**
```
docker: permission denied while trying to connect to Docker daemon
```

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Activate group (or logout/login)
newgrp docker

# Verify
docker ps  # Should work without sudo
```

---

#### Issue: "tea CLI not found"

**Symptoms:**
```
✗ Required command not found: tea
```

**Solution:**
```bash
# Download and install tea
wget https://dl.gitea.com/tea/0.9.2/tea-0.9.2-linux-amd64 -O tea
chmod +x tea
sudo mv tea /usr/local/bin/

# Verify
tea --version
```

---

### Get Help

**Documentation:**
- [User Guide](../user-guide.md) - Complete usage guide
- [CLI Guide](../cli-guide.md) - CLI tool reference
- [Gitea Guide](../gitea-guide.md) - Gitea-specific setup
- [Developer Guide](developer-guide.md) - Development practices

**Community:**
- GitHub Issues: https://github.com/phdsystems/project-management-automation/issues
- Discussions: https://github.com/phdsystems/project-management-automation/discussions

**Quick Commands:**
```bash
# View help
./src/main/cli/gh-org --help

# Check prerequisites
./src/main/cli/gh-org check

# View logs (Gitea)
sudo docker logs gitea

# View configuration
cat .env
cat project-config.json
```

---

## Next Steps

**After successful setup:**

1. **Read Documentation**
   - [Developer Guide](developer-guide.md) - Development practices
   - [User Guide](../user-guide.md) - Feature details
   - [Architecture](../3-design/architecture.md) - System design

2. **Explore Features**
   - Try dry-run mode: `--dry-run`
   - Test individual commands: `teams`, `repos`, `files`
   - Experiment with configuration

3. **Run Tests**
   - Execute test suite: `make -C src/test all`
   - Review test report: `cat src/test/test-report.txt`

4. **Start Contributing**
   - Pick an issue: https://github.com/phdsystems/project-management-automation/issues
   - Read CONTRIBUTING.md
   - Create feature branch
   - Submit pull request

---

## Quick Reference

### Essential Commands

```bash
# Check prerequisites
./src/main/cli/gh-org check

# Dry-run (preview only)
./src/main/cli/gh-org setup --dry-run

# Create teams
./src/main/cli/gh-org teams create

# Create repositories
./src/main/cli/gh-org repos create

# Add template files
./src/main/cli/gh-org files readme
./src/main/cli/gh-org files workflow
./src/main/cli/gh-org files codeowners

# Complete setup
./src/main/cli/gh-org setup

# Run tests
make -C src/test all
```

### Configuration Files

| File | Purpose |
|------|---------|
| `.env` | Backend config (ORG, BACKEND) |
| `project-config.json` | Teams, projects, repos |
| `src/main/templates/` | README, workflow, CODEOWNERS templates |

### Environment Variables

```bash
# Backend selection
BACKEND=github  # Use GitHub
BACKEND=gitea   # Use Gitea

# Organization
ORG=your-org-name

# Optional
DRY_RUN=1       # Enable dry-run mode
VERBOSE=1       # Enable verbose output
```

---

*Last Updated: 2025-10-27*
*Version: 1.0.0*
