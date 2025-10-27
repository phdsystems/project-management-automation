# gh-org CLI

**Version:** 1.0.0

A command-line interface for GitHub organization automation, built following the [GitHub CLI](https://github.com/cli/cli) structure.

## Overview

The `gh-org` CLI provides a user-friendly interface to automate GitHub organization management tasks:
- Create teams and repositories
- Apply template files (README, workflows, CODEOWNERS)
- Validate prerequisites
- Run complete setup workflows

## Architecture

Following the GitHub CLI structure:

```
cli/
├── gh-org                 # Main entry point
├── cmd/                   # Command handlers
│   ├── check.sh          # Prerequisites validation
│   ├── teams.sh          # Team management
│   ├── repos.sh          # Repository management
│   ├── files.sh          # Template file operations
│   └── setup.sh          # Complete setup workflow
├── pkg/                   # Core business logic
│   ├── config.sh         # Configuration handling
│   ├── github.sh         # GitHub API interactions
│   └── templates.sh      # Template operations
└── internal/              # Internal utilities
    ├── output.sh         # Colored output formatting
    └── validation.sh     # Input validation
```

## Installation

### Method 1: Add to PATH

```bash
# Add CLI directory to PATH
export PATH="/home/developer/project-management/src/main/cli:$PATH"

# Add to ~/.bashrc for persistence
echo 'export PATH="/home/developer/project-management/src/main/cli:$PATH"' >> ~/.bashrc

# Test
gh-org --help
```

### Method 2: Symlink to bin

```bash
# Create symlink
sudo ln -s /home/developer/project-management/src/main/cli/gh-org /usr/local/bin/gh-org

# Test
gh-org --help
```

### Method 3: Direct execution

```bash
# Run directly
/home/developer/project-management/src/main/cli/gh-org --help

# Or from project root
./src/main/cli/gh-org --help
```

## Usage

### Basic Commands

```bash
# Check prerequisites
gh-org check

# Create teams
gh-org teams create

# Create repositories
gh-org repos create

# Add template files
gh-org files readme
gh-org files workflow
gh-org files codeowners

# Run complete setup
gh-org setup
```

### Dry-Run Mode

Preview changes without executing:

```bash
gh-org setup --dry-run
gh-org teams create --dry-run
gh-org repos create --dry-run
```

### Verbose Mode

Enable detailed debug output:

```bash
gh-org --verbose setup
gh-org --verbose teams create
```

### Getting Help

```bash
# Main help
gh-org --help

# Command-specific help
gh-org teams --help
gh-org repos --help
gh-org files --help
gh-org setup --help
```

## Commands

### check

Validate prerequisites before running operations.

```bash
gh-org check
```

**Checks:**
- Required CLI tools (gh, jq, git)
- `.env` file exists and is configured
- `project-config.json` exists and is valid JSON
- GitHub authentication is active
- Template files exist

### teams

Manage GitHub teams.

```bash
# Create teams from configuration
gh-org teams create

# Preview (dry-run)
gh-org teams create --dry-run
```

**Features:**
- Creates teams with 'closed' privacy
- Idempotent (skips existing teams)
- Reads from `project-config.json`

### repos

Manage GitHub repositories.

```bash
# Create repositories and assign teams
gh-org repos create

# Preview (dry-run)
gh-org repos create --dry-run
```

**Features:**
- Creates private repositories
- Assigns teams with specified permissions
- Uses naming pattern: `project-{project}-{repo}`
- Idempotent (skips existing repos)

### files

Manage template files in repositories.

```bash
# Add README files
gh-org files readme

# Add GitHub Actions workflows
gh-org files workflow

# Add CODEOWNERS files
gh-org files codeowners

# Preview (dry-run)
gh-org files readme --dry-run
```

**Features:**
- Clones repos, applies templates, commits changes
- Template selection based on repo role
- Automatic role detection from repo name

### setup

Run complete organization setup.

```bash
# Full setup
gh-org setup

# Preview all steps (dry-run)
gh-org setup --dry-run
```

**Execution order:**
1. Check prerequisites
2. Create teams
3. Create repositories
4. Add README files
5. Add workflow files
6. Add CODEOWNERS files

## Configuration

### .env File

Located at project root:

```bash
ORG=your-github-org-name
```

### project-config.json

Located at project root:

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

### Templates

Located in `src/main/templates/`:

- `README-{role}.md` - README templates by role
- `workflow-{role}.yml` - GitHub Actions workflows by role
- `CODEOWNERS` - Code review assignments

## Examples

### Complete Setup Workflow

```bash
# 1. Check prerequisites
gh-org check

# 2. Preview everything first
gh-org setup --dry-run

# 3. Run complete setup
gh-org setup
```

### Individual Operations

```bash
# Create just teams
gh-org teams create

# Create just repositories
gh-org repos create

# Add only README files
gh-org files readme
```

### Debugging

```bash
# Enable verbose output
gh-org --verbose setup

# Check specific issues
gh-org check

# Dry-run to see what would happen
gh-org --dry-run setup
```

## Output

The CLI provides colored, formatted output:

- ✓ **Green checkmarks** - Success
- ✗ **Red X** - Errors
- ℹ **Blue info** - Information
- ⚠ **Yellow warning** - Warnings
- **[DRY RUN]** - Preview mode

## Error Handling

- Commands return non-zero exit codes on failure
- Detailed error messages with context
- Validation before operations
- Idempotent operations (safe to retry)

## Comparison: CLI vs Makefile

| Feature | CLI (`gh-org`) | Makefile (`make`) |
|---------|----------------|-------------------|
| **Ease of use** | ✓ User-friendly commands | Shell-like targets |
| **Help text** | ✓ Rich help (`--help`) | Limited (`#` comments) |
| **Error messages** | ✓ Colored, detailed | Plain text |
| **Dry-run** | ✓ `--dry-run` flag | `DRY_RUN=1` variable |
| **Modularity** | ✓ Separate cmd/pkg structure | Single Makefile |
| **Testing** | Easy to unit test | Harder to test |
| **Portability** | Works anywhere | Requires `make` |

**Recommendation:** Use CLI for interactive use, Makefile for CI/CD pipelines.

## Development

### Adding New Commands

1. Create command handler in `cmd/`:
   ```bash
   cmd/my-command.sh
   ```

2. Implement command logic:
   ```bash
   cmd::mycommand::run() {
     # Implementation
   }

   cmd::mycommand::help() {
     # Help text
   }
   ```

3. Source in main `gh-org`:
   ```bash
   source "${CLI_DIR}/cmd/my-command.sh"
   ```

4. Add to router:
   ```bash
   case "$command" in
     mycommand)
       cmd::mycommand::run "$ROOT_DIR"
       ;;
   esac
   ```

### Adding Core Logic

Add reusable functions to `pkg/`:

```bash
# pkg/mymodule.sh
mymodule::do_something() {
  # Logic
}
```

Source in command handlers:

```bash
source "${SCRIPT_DIR}/../pkg/mymodule.sh"
```

## Troubleshooting

### Command not found

```bash
# Option 1: Use full path
/home/developer/project-management/src/main/cli/gh-org --help

# Option 2: Add to PATH
export PATH="/home/developer/project-management/src/main/cli:$PATH"
```

### Permission denied

```bash
chmod +x /home/developer/project-management/src/main/cli/gh-org
```

### GitHub authentication failed

```bash
gh auth login
gh auth status
```

### Configuration errors

```bash
# Validate JSON
jq . project-config.json

# Check .env file
cat .env
```

## Related Documentation

- **User Guide:** [doc/user-guide.md](../../../doc/user-guide.md)
- **Quick Reference:** [doc/quick-reference.md](../../../doc/quick-reference.md)
- **Makefile:** [src/main/Makefile](../Makefile)
- **Tests:** [src/test/](../../test/)

## License

MIT License
