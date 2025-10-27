# GitHub Organization Project Management Automation

**Version:** 2.0.0
**Last Updated:** 2025-10-27

## Overview

Automates GitHub organization setup: creates teams, repositories, and standard files (README, workflows, CODEOWNERS) from a single JSON configuration.

**Key features:**
- ✅ Idempotent operations (safe to run multiple times)
- ✅ Dry-run mode for testing
- ✅ JSON-based configuration
- ✅ Automatic template application by role

## Quick Start

```bash
# 1. Configure environment
cp .env.example .env
nano .env  # Set your ORG name

# 2. Configure projects
nano project-config.json

# 3. Run (preview first)
make all DRY_RUN=1

# 4. Execute
make all
```

## Prerequisites

- `gh` CLI (GitHub CLI) - https://cli.github.com
- `jq` (JSON processor)
- `git`
- GitHub authentication: `gh auth login`

## Project Structure

```
project-management/
├── src/
│   ├── main/
│   │   ├── Makefile              # Main automation script
│   │   └── templates/            # README/workflow/CODEOWNERS templates
│   └── test/                     # Test suite
├── doc/                          # Detailed documentation
│   ├── user-guide.md             # Complete setup and usage guide
│   ├── quick-reference.md        # Command cheat sheet
│   ├── TEST-REPORT.md            # Test results
│   └── ci-parallelization-strategies.md
├── .env                          # Your configuration (gitignored)
├── .env.example                  # Configuration template
└── project-config.json           # Projects/teams/repos definition
```

## Documentation

| Document | Purpose |
|----------|---------|
| **[User Guide](doc/user-guide.md)** | Complete setup, usage, architecture diagrams, troubleshooting |
| **[Quick Reference](doc/quick-reference.md)** | Command cheat sheet for power users |
| **[Test Report](doc/TEST-REPORT.md)** | Test results and findings |
| **[Test Suite](src/test/README.md)** | Testing documentation for contributors |
| **[CI Parallelization](doc/ci-parallelization-strategies.md)** | GitHub Actions optimization strategies |

## Common Commands

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
ORG=your-github-org-name
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

## Getting Help

- 📚 **Full documentation:** See [doc/user-guide.md](doc/user-guide.md)
- 🐛 **Troubleshooting:** See [doc/user-guide.md - Troubleshooting section](doc/user-guide.md#troubleshooting)
- 🧪 **Running tests:** See [src/test/README.md](src/test/README.md)

## License

MIT License

---

*For detailed architecture, workflows, error handling, and advanced usage, see the [User Guide](doc/user-guide.md).*
