# Gitea Setup Guide

**Version:** 1.0.0
**Last Updated:** 2025-10-27

## TL;DR

**Use gh-org CLI with Gitea**: Set `BACKEND=gitea` in `.env`, install `tea` CLI, authenticate with `tea login add`, then run `gh-org setup`. **Same commands**: All gh-org commands work identically for Gitea. **Permissions**: GitHub permissions (pull/push/admin) automatically map to Gitea (read/write/admin).

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Authentication](#authentication)
- [Usage](#usage)
- [Differences from GitHub](#differences-from-github)
- [Troubleshooting](#troubleshooting)
- [Examples](#examples)

---

## Overview

The `gh-org` CLI supports both GitHub and Gitea backends. This guide covers using the tool with a self-hosted Gitea instance.

### What is Gitea?

**Gitea** is a lightweight, self-hosted Git service similar to GitHub, GitLab, and Bitbucket. It provides:
- Git repository hosting
- Organizations and teams
- Pull requests and code review
- Issue tracking
- CI/CD integration

**Key advantages:**
- ✅ Open source (MIT license)
- ✅ Self-hosted (full control)
- ✅ Lightweight (single binary)
- ✅ Fast and efficient
- ✅ Docker-friendly

### Official Resources

- **Website:** https://gitea.io
- **Documentation:** https://docs.gitea.io
- **GitHub:** https://github.com/go-gitea/gitea
- **tea CLI:** https://gitea.com/gitea/tea

---

## Prerequisites

### Required

1. **Gitea instance** (self-hosted or cloud)
   - Version 1.16+ recommended
   - Admin access to create organizations

2. **tea CLI** - Gitea command-line tool
   - Similar to GitHub's `gh` CLI
   - Official Gitea CLI

3. **Common tools**
   - `jq` - JSON processor
   - `git` - Version control

### Installation

#### 1. Install Gitea (if self-hosting)

**Docker (recommended):**
```bash
docker run -d \
  --name=gitea \
  -p 3000:3000 \
  -p 222:22 \
  -v /var/lib/gitea:/data \
  gitea/gitea:latest
```

**Binary:**
```bash
wget -O gitea https://dl.gitea.com/gitea/1.21/gitea-1.21-linux-amd64
chmod +x gitea
./gitea web
```

Access at: http://localhost:3000

#### 2. Install tea CLI

**From releases:**
```bash
# Download latest release
wget https://dl.gitea.com/tea/0.9.2/tea-0.9.2-linux-amd64 -O tea
chmod +x tea
sudo mv tea /usr/local/bin/

# Verify installation
tea --version
```

**From source (requires Go):**
```bash
go install gitea.com/gitea/tea@latest
```

**Package managers:**
```bash
# Homebrew (macOS/Linux)
brew install tea

# AUR (Arch Linux)
yay -S gitea-tea
```

#### 3. Install common tools

```bash
# Debian/Ubuntu
sudo apt-get install jq git

# macOS
brew install jq git
```

---

## Configuration

### 1. Configure .env file

```bash
cd project-management
cp .env.example .env
nano .env
```

**Set backend to Gitea:**
```bash
# Your Gitea organization name
ORG=my-gitea-org

# Use Gitea backend
BACKEND=gitea
```

### 2. Configure project-config.json

Same format as GitHub - no changes needed!

```json
{
  "teams": ["frontend-team", "backend-team", "infra-team"],
  "projects": [
    {
      "name": "alpha",
      "repos": [
        {"name": "frontend", "team": "frontend-team", "permission": "push"},
        {"name": "backend", "team": "backend-team", "permission": "push"},
        {"name": "infra", "team": "infra-team", "permission": "admin"}
      ]
    }
  ]
}
```

### 3. Create organization in Gitea

**Via Web UI:**
1. Log in to Gitea
2. Click "+" → "New Organization"
3. Enter organization name (must match `ORG` in .env)
4. Create organization

**Note:** The CLI will verify the organization exists but cannot create it automatically.

---

## Authentication

### 1. Add Gitea login to tea

```bash
tea login add
```

You'll be prompted for:
- **Gitea instance URL:** e.g., `https://gitea.example.com` or `http://localhost:3000`
- **Username:** Your Gitea username
- **Password or Token:** Your password or access token

**Creating an access token (recommended):**
1. Log in to Gitea web UI
2. Settings → Applications → Generate New Token
3. Select scopes: `repo`, `org`, `user`
4. Copy token
5. Use in `tea login add`

### 2. Verify authentication

```bash
# List logins
tea login list

# Should show active login with asterisk (*)
# * https://gitea.example.com (username)

# Test authentication
tea repos list
```

### 3. Set default login (if multiple)

```bash
tea login default https://gitea.example.com
```

---

## Usage

### Commands

**All commands work exactly the same as with GitHub:**

```bash
# Check prerequisites
./src/main/cli/gh-org check

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

# Dry-run mode
./src/main/cli/gh-org setup --dry-run
```

### Output

```bash
$ ./src/main/cli/gh-org teams create

Creating Gitea teams
ℹ Creating team: frontend-team
✓ Team created: frontend-team
ℹ Creating team: backend-team
✓ Team created: backend-team
✓ All teams created successfully
```

Note: Output shows "Gitea" instead of "GitHub" based on BACKEND setting.

---

## Differences from GitHub

### Permission Mapping

GitHub and Gitea use different permission models. The CLI automatically maps them:

| GitHub Permission | Gitea Permission | Access Level |
|-------------------|------------------|--------------|
| `pull` | `read` | Read-only |
| `push` | `write` | Read + write |
| `triage` | `write` | Read + write + issues |
| `maintain` | `write` | Read + write + issues |
| `admin` | `admin` | Full control |

### Team Privacy

- **GitHub:** Teams can be `secret` or `closed`
- **Gitea:** All teams are visible to organization members

The CLI creates teams with default Gitea settings.

### API Differences

| Feature | GitHub API | Gitea API |
|---------|------------|-----------|
| **Teams** | `/orgs/{org}/teams` | `/orgs/{org}/teams` |
| **Repos** | `gh repo create` | `tea repos create` |
| **Permissions** | `PUT /teams/{id}/repos/{repo}` | `tea repos add-team` |

The CLI handles these differences automatically.

### Feature Parity

**Supported (100% compatible):**
- ✅ Create teams
- ✅ Create repositories
- ✅ Assign team permissions
- ✅ Clone repositories
- ✅ Add/commit/push files
- ✅ Template application

**Differences:**
- ⚠️ Team privacy settings (Gitea simpler)
- ⚠️ Some permission levels mapped

---

## Troubleshooting

### tea CLI not found

**Symptom:**
```
✗ Required command not found: tea
ℹ Install tea CLI: https://gitea.com/gitea/tea
```

**Solution:**
```bash
# Download and install tea
wget https://dl.gitea.com/tea/0.9.2/tea-0.9.2-linux-amd64 -O tea
chmod +x tea
sudo mv tea /usr/local/bin/
```

---

### Not authenticated with Gitea

**Symptom:**
```
✗ Not authenticated with Gitea
ℹ Run: tea login add
```

**Solution:**
```bash
# Add login
tea login add

# Verify
tea login list
```

---

### Organization not found

**Symptom:**
```
⚠ Organization may not exist or you don't have access: my-org
ℹ Create organization via Gitea web UI: Site Admin > Organizations
```

**Solution:**
1. Log in to Gitea web UI
2. Create organization: "+" → "New Organization"
3. Ensure name matches `ORG` in .env
4. Verify you have admin access

---

### Team already exists error

**Symptom:**
```
✗ Failed to create team: frontend-team
```

**Solution:**
```bash
# List existing teams
tea teams list --organization my-org

# The CLI should skip existing teams (check for bugs)
# Workaround: Delete team via web UI if incorrect
```

---

### Clone failed

**Symptom:**
```
✗ Failed to clone repository: my-org/my-repo
```

**Solution:**
```bash
# Verify repo exists
tea repos list --organization my-org

# Check SSH keys
ssh -T git@gitea.example.com

# Or use HTTPS with token
git config --global credential.helper store
```

---

### Permission denied

**Symptom:**
```
✗ Failed to assign team: frontend-team -> project-alpha-frontend
```

**Solution:**
```bash
# Verify you have admin access to organization
# Check token scopes include: repo, org, user

# Recreate token with proper scopes
# Settings → Applications → Generate New Token
```

---

## Examples

### Example 1: Local Gitea Setup

**Setup Gitea locally:**
```bash
# Run Gitea in Docker
docker run -d \
  --name=gitea \
  -p 3000:3000 \
  -v /var/lib/gitea:/data \
  gitea/gitea:latest

# Access: http://localhost:3000
# Complete initial setup
# Create admin user
```

**Configure CLI:**
```bash
# Authenticate
tea login add
# URL: http://localhost:3000
# Username: admin
# Token: (create in Settings → Applications)

# Configure project
cd project-management
cp .env.example .env

# Edit .env
echo "ORG=my-local-org" > .env
echo "BACKEND=gitea" >> .env

# Create organization via web UI
# Then run automation
./src/main/cli/gh-org setup --dry-run
./src/main/cli/gh-org setup
```

---

### Example 2: Migration from GitHub to Gitea

**Step 1: Export GitHub config**
```bash
# Your existing .env
ORG=my-github-org
BACKEND=github

# Your existing project-config.json (no changes needed)
```

**Step 2: Setup Gitea**
```bash
# Add Gitea login
tea login add

# Create Gitea organization (web UI)

# Update .env for Gitea
cp .env .env.github.backup
nano .env
# Change: BACKEND=gitea
# Change: ORG=my-gitea-org
```

**Step 3: Run automation**
```bash
# Preview
./src/main/cli/gh-org setup --dry-run

# Execute
./src/main/cli/gh-org setup
```

**Result:** Same structure created in Gitea!

---

### Example 3: Multi-platform setup

**Use both platforms:**

```bash
# Create separate config files
cp .env .env.github
cp .env .env.gitea

# .env.github
echo "ORG=my-github-org" > .env.github
echo "BACKEND=github" >> .env.github

# .env.gitea
echo "ORG=my-gitea-org" > .env.gitea
echo "BACKEND=gitea" >> .env.gitea

# Run for GitHub
cp .env.github .env
./src/main/cli/gh-org setup

# Run for Gitea
cp .env.gitea .env
./src/main/cli/gh-org setup
```

**Result:** Identical structures on both platforms!

---

## Comparison: GitHub vs Gitea

### CLI Commands

| Operation | GitHub | Gitea |
|-----------|--------|-------|
| **Authenticate** | `gh auth login` | `tea login add` |
| **List repos** | `gh repo list` | `tea repos list` |
| **Create repo** | `gh repo create` | `tea repos create` |
| **List teams** | `gh api /orgs/{org}/teams` | `tea teams list --organization {org}` |
| **Create team** | `gh api -X POST /orgs/{org}/teams` | `tea teams create --organization {org}` |

### gh-org CLI Usage

**Identical for both platforms:**

```bash
# Same commands
gh-org check
gh-org teams create
gh-org repos create
gh-org files readme
gh-org setup

# Same flags
--dry-run
--verbose
--help

# Same configuration
project-config.json (no changes)
```

**Only difference:** Set `BACKEND=gitea` in `.env`

---

## Advanced Configuration

### Custom Gitea URL

```bash
# Add login with custom URL
tea login add
# URL: https://git.mycompany.com
# Port: 443 (or custom)

# Verify
tea login list
```

### Using SSH

```bash
# Add SSH key to Gitea
ssh-keygen -t ed25519 -C "your@email.com"
cat ~/.ssh/id_ed25519.pub

# Add in Gitea: Settings → SSH/GPG Keys → Add Key

# Test
ssh -T git@gitea.example.com
```

### Using HTTPS with Tokens

```bash
# Create token in Gitea
# Settings → Applications → Generate New Token

# Configure git credential helper
git config --global credential.helper store

# First clone will prompt for credentials
# Username: your-username
# Password: your-token

# Subsequent operations will use stored credentials
```

---

## Benefits of Self-Hosted Gitea

### 1. Full Control
- Own your data
- Custom configurations
- No vendor lock-in

### 2. Privacy
- Code stays on your infrastructure
- No external access
- Compliance-friendly

### 3. Cost
- No per-user fees
- Unlimited repositories
- Unlimited storage (your hardware)

### 4. Performance
- Local network speed
- No rate limits
- Customizable resources

### 5. Customization
- Custom authentication (LDAP, OAuth)
- Custom themes
- Custom webhooks

---

## Related Documentation

- **CLI Guide:** [cli-guide.md](cli-guide.md) - Complete CLI documentation
- **User Guide:** [user-guide.md](user-guide.md) - Makefile approach
- **Quick Reference:** [quick-reference.md](quick-reference.md) - Command cheat sheet

---

## References

- **Gitea:** https://gitea.io
- **Gitea Docs:** https://docs.gitea.io
- **tea CLI:** https://gitea.com/gitea/tea
- **tea Docs:** https://gitea.com/gitea/tea/src/branch/main/README.md
- **Gitea API:** https://docs.gitea.io/en-us/api-usage/

---

*Last Updated: 2025-10-27*
