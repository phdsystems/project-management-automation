# Git Platform Organization Automation (GitHub/Gitea)

**Version:** 2.1.0
**Last Updated:** 2025-10-27

## Overview

Automates Git platform organization setup: creates teams, repositories, and standard files (README, workflows, CODEOWNERS) from a single JSON configuration.

**Supports:**
- ✅ **GitHub** - GitHub.com or GitHub Enterprise
- ✅ **Gitea** - Self-hosted Gitea instances

**Key features:**
- ✅ Idempotent operations (safe to run multiple times)
- ✅ Dry-run mode for testing
- ✅ JSON-based configuration
- ✅ Automatic template application by role
- ✅ Backend-agnostic (same config works for both)

## Quick Start

### Option 1: CLI (Recommended)

```bash
# 1. Configure environment
cp .env.example .env
nano .env  # Set your ORG name

# 2. Configure projects
nano project-config.json

# 3. Run (preview first)
./src/main/cli/gh-org setup --dry-run

# 4. Execute
./src/main/cli/gh-org setup
```

### Option 2: Makefile

```bash
# 1. Configure environment
cp .env.example .env
nano .env  # Set your ORG name

# 2. Configure projects
nano project-config.json

# 3. Run (preview first)
make -C src/main all DRY_RUN=1

# 4. Execute
make -C src/main all
```

## Prerequisites

**For GitHub:**
- `gh` CLI - https://cli.github.com
- GitHub authentication: `gh auth login`

**For Gitea:**
- `tea` CLI - https://gitea.com/gitea/tea
- Gitea authentication: `tea login add`

**Common:**
- `jq` (JSON processor)
- `git`

## Project Structure

```
project-management/
├── src/
│   ├── main/
│   │   ├── cli/                  # CLI tool (gh-org)
│   │   │   ├── gh-org           # Main CLI entry point
│   │   │   ├── cmd/             # Command handlers
│   │   │   ├── pkg/             # Core logic modules
│   │   │   └── internal/        # Internal utilities
│   │   ├── Makefile             # Automation Makefile
│   │   └── templates/           # README/workflow/CODEOWNERS templates
│   └── test/                    # Test suite
├── doc/                         # Detailed documentation
│   ├── user-guide.md            # Complete setup and usage guide
│   ├── quick-reference.md       # Command cheat sheet
│   ├── TEST-REPORT.md           # Test results
│   └── ci-parallelization-strategies.md
├── .env                         # Your configuration (gitignored)
├── .env.example                 # Configuration template
└── project-config.json          # Projects/teams/repos definition
```

## Documentation

| Document | Purpose |
|----------|---------|
| **[User Guide](doc/user-guide.md)** | Complete setup, usage, architecture diagrams, troubleshooting |
| **[CLI Guide](doc/cli-guide.md)** | CLI tool documentation with diagrams |
| **[Gitea Guide](doc/gitea-guide.md)** | Using with self-hosted Gitea |
| **[GitHub vs Gitea](doc/github-vs-gitea-comparison.md)** | Complete feature comparison and decision guide |
| **[Quick Reference](doc/quick-reference.md)** | Command cheat sheet for power users |
| **[CLI README](src/main/cli/README.md)** | Technical CLI reference |
| **[Test Report](doc/TEST-REPORT.md)** | Test results and findings |
| **[Test Suite](src/test/README.md)** | Testing documentation for contributors |
| **[CI Parallelization](doc/ci-parallelization-strategies.md)** | GitHub Actions optimization strategies |

## Common Commands

### Using CLI (gh-org)

```bash
# Check prerequisites
./src/main/cli/gh-org check

# Run complete setup
./src/main/cli/gh-org setup

# Individual operations
./src/main/cli/gh-org teams create
./src/main/cli/gh-org repos create
./src/main/cli/gh-org files readme
./src/main/cli/gh-org files workflow
./src/main/cli/gh-org files codeowners

# Dry-run mode (preview changes)
./src/main/cli/gh-org setup --dry-run

# Get help
./src/main/cli/gh-org --help
./src/main/cli/gh-org teams --help
```

### Using Makefile

```bash
# Run everything
make -C src/main all

# Individual targets
make -C src/main teams          # Create teams only
make -C src/main repos          # Create repositories only
make -C src/main readmes        # Add README files only

# Dry-run mode (preview changes)
make -C src/main all DRY_RUN=1

# Clean temporary files
make -C src/main clean
```

## Configuration

**`.env` file:**
```bash
# For GitHub (default)
ORG=your-github-org
BACKEND=github  # or omit (default)

# For Gitea
ORG=your-gitea-org
BACKEND=gitea
```

**`project-config.json`:**
```json
{
  "teams": ["frontend-team", "backend-team"],
  "projects": [
    {
      "name": "alpha",
      "repos": [
        {"name": "frontend", "team": "frontend-team", "permission": "push"}
      ]
    }
  ]
}
```

Creates: `project-alpha-frontend` assigned to `frontend-team` with push access.

**Note:** Same configuration works for both GitHub and Gitea. Only the BACKEND variable changes.

## Getting Help

- 📚 **Full documentation:** See [doc/user-guide.md](doc/user-guide.md)
- 🐛 **Troubleshooting:** See [doc/user-guide.md - Troubleshooting section](doc/user-guide.md#troubleshooting)
- 🧪 **Running tests:** See [src/test/README.md](src/test/README.md)

## License

MIT License

---

*For detailed architecture, workflows, error handling, and advanced usage, see the [User Guide](doc/user-guide.md).*
