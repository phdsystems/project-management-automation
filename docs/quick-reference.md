# Quick Reference Card

**GitHub Organization Automation - Cheat Sheet**

## Essential Commands

```bash
# Preview changes (always start here)
make all DRY_RUN=1

# Execute full automation
make all

# Individual targets
make teams          # Create teams only
make repos          # Create repositories only
make readmes        # Add README files only
make workflows      # Add GitHub Actions workflows only
make codeowners     # Add CODEOWNERS files only

# Validation
make check-prereqs  # Check prerequisites

# Cleanup
make clean          # Remove temporary files
```

---

## Configuration Files

### `.env` (Required)

```bash
ORG=your-github-org-name
CONFIG=project-config.json
DEFAULT_BRANCH=main
DRY_RUN=0
VERBOSE=0
```

### `project-config.json` (Required)

```json
{
  "teams": ["team1", "team2"],
  "projects": [{
    "name": "project-name",
    "repos": [{
      "name": "frontend",
      "team": "team1",
      "permission": "push"
    }]
  }]
}
```

---

## Permission Levels

| Permission | Access |
|------------|--------|
| `pull` | Read-only |
| `push` | Read + write |
| `maintain` | Push + manage issues/PRs |
| `admin` | Full admin access |
| `triage` | Manage issues/PRs (no code) |

---

## Repository Naming

**Pattern:** `project-{PROJECT_NAME}-{REPO_NAME}`

**Examples:**
- Project: `alpha`, Repo: `frontend` → `project-alpha-frontend`
- Project: `beta`, Repo: `backend` → `project-beta-backend`

---

## Template Matching

| Repo Name | README Template | Workflow Template |
|-----------|-----------------|-------------------|
| `frontend` | `README-frontend.md` | `workflow-frontend.yml` |
| `backend` | `README-backend.md` | `workflow-backend.yml` |
| `infra` | `README-infra.md` | `workflow-infra.yml` |

---

## GitHub CLI Commands

```bash
# Authenticate
gh auth login

# Check authentication
gh auth status

# List teams
gh api /orgs/YOUR_ORG/teams

# Check account type
gh api /users/YOUR_ORG | jq -r '.type'

# List repositories
gh repo list YOUR_ORG

# Delete repository
gh repo delete YOUR_ORG/REPO_NAME --yes
```

---

## Troubleshooting

### Prerequisites Check Failed

```bash
# Check tools installed
gh --version
jq --version
make --version
git --version

# Authenticate
gh auth login

# Verify authentication
gh auth status
```

### Invalid JSON

```bash
# Validate JSON syntax
jq . project-config.json
```

### Team Creation Failed (404)

```bash
# Verify you have an Organization (not User account)
gh api /users/YOUR_NAME | jq -r '.type'
# Must be: "Organization"

# Check permissions
gh api /orgs/YOUR_ORG/memberships/YOUR_USERNAME | jq -r '.role'
# Should be: "admin" or "owner"
```

---

## Example Configurations

### Minimal (Single Project)

```json
{
  "teams": ["dev-team"],
  "projects": [{
    "name": "app",
    "repos": [{
      "name": "frontend",
      "team": "dev-team",
      "permission": "push"
    }]
  }]
}
```

**Creates:**
- Team: `dev-team`
- Repo: `project-app-frontend`

### Multiple Projects

```json
{
  "teams": ["frontend-team", "backend-team"],
  "projects": [
    {
      "name": "alpha",
      "repos": [
        {"name": "frontend", "team": "frontend-team", "permission": "push"},
        {"name": "backend", "team": "backend-team", "permission": "push"}
      ]
    },
    {
      "name": "beta",
      "repos": [
        {"name": "frontend", "team": "frontend-team", "permission": "push"},
        {"name": "backend", "team": "backend-team", "permission": "push"}
      ]
    }
  ]
}
```

**Creates:**
- 2 teams: `frontend-team`, `backend-team`
- 4 repos: `project-alpha-frontend`, `project-alpha-backend`, `project-beta-frontend`, `project-beta-backend`

### Microservices

```json
{
  "teams": ["auth-team", "payment-team", "platform-team"],
  "projects": [{
    "name": "prod",
    "repos": [
      {"name": "auth-service", "team": "auth-team", "permission": "push"},
      {"name": "payment-service", "team": "payment-team", "permission": "push"},
      {"name": "platform", "team": "platform-team", "permission": "admin"}
    ]
  }]
}
```

---

## Best Practices

✅ **DO:**
- Always run dry-run first: `make all DRY_RUN=1`
- Start small (1 team, 1 project) for testing
- Version control your `project-config.json`
- Review template files before running
- Use appropriate permission levels
- Document your team structure

❌ **DON'T:**
- Commit `.env` file (gitignored automatically)
- Use personal user account (requires Organization)
- Skip dry-run mode
- Grant `admin` permission unnecessarily
- Delete `.env.example` file

---

## File Structure

```
project-management/
├── .env                      # Your config (gitignored)
├── .env.example              # Template
├── project-config.json       # Teams/projects config
├── Makefile                  # Main automation
├── README.md                 # Project overview
├── TEST-REPORT.md            # Test results
├── templates/                # Template files
│   ├── README-frontend.md
│   ├── README-backend.md
│   ├── README-infra.md
│   ├── workflow-frontend.yml
│   ├── workflow-backend.yml
│   ├── workflow-infra.yml
│   └── CODEOWNERS
├── tests/                    # Test suite
│   ├── run-tests.sh
│   ├── unit/
│   ├── integration/
│   └── e2e/
└── docs/                     # Documentation
    ├── user-guide.md
    ├── quick-reference.md
    └── ci-parallelization-strategies.md
```

---

## Workflow Order

```
1. Prerequisites Check
   ↓
2. Create Teams
   ↓
3. Create Repositories
   ↓
4. Assign Teams to Repos
   ↓
5. Add README Files
   ↓
6. Add Workflow Files
   ↓
7. Add CODEOWNERS Files
   ↓
8. Complete ✅
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error occurred |

---

## Getting Help

```bash
# View Makefile help
make help

# Run tests
./tests/run-tests.sh

# View GitHub CLI help
gh help api
gh help repo
```

**Documentation:**
- User Guide: `docs/user-guide.md`
- Test Suite: `tests/README.md`
- CI Docs: `docs/ci-parallelization-strategies.md`

**Support:**
- Issues: https://github.com/phdsystems/project-management-automation/issues
- Discussions: https://github.com/phdsystems/project-management-automation/discussions

---

## Version Info

**Current Version:** 2.0.0
**Last Updated:** 2025-10-27

**Requirements:**
- GitHub Organization (not personal account)
- GitHub CLI (`gh`) with admin:org, repo, workflow scopes
- `jq` for JSON processing
- `make` for automation
- `git` for version control

---

**Quick Start:**
```bash
cp .env.example .env           # 1. Configure
nano .env                      # 2. Set ORG
nano project-config.json       # 3. Define projects
gh auth login                  # 4. Authenticate
make all DRY_RUN=1            # 5. Preview
make all                       # 6. Execute
```

**Done!** 🚀
