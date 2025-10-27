# Mermaid Diagrams Index

**Locations:** `doc/user-guide.md`, `doc/cli-guide.md`, `doc/3-design/architecture.md`
**Total Diagrams:** 26 (12 in User Guide + 7 in CLI Guide + 7 in Architecture)
**Last Updated:** 2025-10-27

## Overview

The documentation includes 26 mermaid diagrams across three main documents:
- **User Guide** (12 diagrams) - Makefile workflows, configurations, and decision trees
- **CLI Guide** (7 diagrams) - CLI architecture, command flows, and comparisons
- **Architecture Design** (7 diagrams) - Backend abstraction, CLI structure, and system architecture

---

## Diagram List

### 1. Quick Start Visual Flow

**Location:** Quick Start section
**Type:** Flowchart (Linear)
**Purpose:** Shows 6-step setup process with decision point

**Flow:**
```
Clone Repo → Configure .env → Create config → Authenticate →
Dry-run → Review OK? → [Fix or Execute] → Done
```

**Use Case:** First-time users getting started

---

### 2. Prerequisites Checklist

**Location:** Prerequisites section
**Type:** Flowchart (Decision Tree)
**Purpose:** Interactive checklist for all prerequisites

**Checks:**
- Tools: gh, jq, make, git
- GitHub authentication
- Organization account
- Admin permissions

**Use Case:** Troubleshooting setup issues

---

### 3. Configuration Architecture

**Location:** Configuration section
**Type:** Graph (3 subgraphs)
**Purpose:** Shows how config files flow through system

**Components:**
- Configuration Files (.env, config.json, templates)
- Makefile Processing (load, parse, match)
- GitHub API (teams, repos, templates)

**Use Case:** Understanding system architecture

---

### 4. Repository Naming Convention

**Location:** Configuration section
**Type:** Flowchart (Multiple flows)
**Purpose:** Demonstrates naming pattern with examples

**Examples:**
- alpha + frontend → project-alpha-frontend
- beta + backend → project-beta-backend
- prod + infra → project-prod-infra

**Use Case:** Understanding repo naming

---

### 5. Template Matching Logic

**Location:** Configuration section
**Type:** Flowchart (Parallel flows)
**Purpose:** Shows how repo names map to templates

**Mappings:**
- frontend → README-frontend.md + workflow-frontend.yml
- backend → README-backend.md + workflow-backend.yml

**Use Case:** Customizing templates

---

### 6. Full Automation Workflow

**Location:** Basic Usage section
**Type:** Flowchart (Complex)
**Purpose:** Complete execution flow with decision points

**Stages:**
1. Prerequisites check
2. Team creation (with idempotency)
3. Repository creation (with idempotency)
4. Team assignment
5. README addition
6. Workflow addition
7. CODEOWNERS addition

**Use Case:** Understanding complete process

---

### 7. Workflow Decision Tree

**Location:** Common Workflows section
**Type:** Flowchart (Decision tree)
**Purpose:** Help users choose correct workflow

**Options:**
- Single project → Workflow 1
- Multiple projects → Workflow 2
- Microservices → Workflow 3
- Add to existing → Workflow 4
- Update files → Workflow 5

**Use Case:** Selecting appropriate workflow

---

### 8. Workflow 1 Visual (Single Project)

**Location:** Workflow 1 section
**Type:** Graph (3 subgraphs)
**Purpose:** Shows result of single project setup

**Components:**
- Team created
- Repositories created
- Files added to each repo

**Use Case:** Visualizing simple setup

---

### 9. Workflow 2 Visual (Multiple Projects)

**Location:** Workflow 2 section
**Type:** Graph (3 subgraphs)
**Purpose:** Shows team-to-repo relationships

**Components:**
- Teams (frontend-team, backend-team)
- Project Alpha repos
- Project Beta repos
- Permission mappings

**Use Case:** Understanding shared teams

---

### 10. Troubleshooting Decision Tree

**Location:** Troubleshooting section
**Type:** Flowchart (Decision tree)
**Purpose:** Quick diagnosis of common issues

**Issues Covered:**
- .env not found
- ORG not set
- gh not installed
- Not authenticated
- Team 404 errors
- Repo already exists
- Invalid JSON

**Use Case:** Fast problem resolution

---

### 11. Best Practices Workflow

**Location:** Best Practices section
**Type:** Flowchart (Linear with loop)
**Purpose:** Shows recommended workflow

**Steps:**
1. Start small
2. Dry-run first
3. Review output
4. Fix or execute
5. Verify results
6. Version control
7. Document changes
8. Scale up

**Use Case:** Following best practices

---

### 12. Permission Hierarchy

**Location:** Reference section
**Type:** Graph (Hierarchical)
**Purpose:** Shows permission levels from least to most

**Levels:**
- pull (Read only)
- push (Read + write)
- triage (+ Manage issues)
- maintain (+ Manage issues/PRs)
- admin (Full control)

**Use Case:** Choosing correct permissions

---

## CLI Guide Diagrams (doc/cli-guide.md)

### 13. CLI High-Level Architecture

**Location:** Architecture section
**Type:** Graph (4 subgraphs)
**Purpose:** Shows CLI package structure and dependencies

**Components:**
- CLI Entry Point (gh-org)
- Command Layer (cmd/)
- Business Logic (pkg/)
- Utilities (internal/)
- External Dependencies (gh, jq, git)

**Use Case:** Understanding CLI architecture

---

### 14. Command Hierarchy

**Location:** Commands Reference section
**Type:** Graph (Tree structure)
**Purpose:** Shows all commands and subcommands

**Structure:**
```
gh-org
├── check
├── teams → create
├── repos → create
├── files → readme/workflow/codeowners
├── setup
├── version
└── help
```

**Use Case:** Discovering available commands

---

### 15. Complete Setup Workflow (CLI)

**Location:** Workflows section
**Type:** Flowchart (Complex with error handling)
**Purpose:** Shows complete setup execution with error paths

**Stages:**
1. Prerequisites check
2. Create teams (continue on error)
3. Create repos (continue on error)
4. Add READMEs (continue on error)
5. Add workflows (continue on error)
6. Add CODEOWNERS (continue on error)
7. Summary (success or partial failure)

**Use Case:** Understanding CLI execution flow

---

### 16. File Addition Workflow

**Location:** Workflows section
**Type:** Flowchart (Linear with branch)
**Purpose:** Shows how template files are applied

**Steps:**
- Load config → Get role → Select template → Dry-run check
- If dry-run: Print preview
- If execute: Clone → Copy → Commit → Push → Cleanup

**Use Case:** Understanding file operations

---

### 17. Data Flow

**Location:** Workflows section
**Type:** Flowchart (4 subgraphs)
**Purpose:** Shows data flow through CLI

**Components:**
- Input (.env, config.json, templates)
- CLI Processing (parse, load, execute)
- GitHub API (teams, repos, permissions)
- Output (created resources, console)

**Use Case:** Understanding data pipeline

---

### 18. Command Execution Sequence

**Location:** Diagrams section
**Type:** Sequence diagram
**Purpose:** Shows interaction between components

**Participants:**
- User
- CLI (gh-org)
- Command Handler
- Business Logic
- GitHub API

**Flow:** User command → Parse → Route → Load config → API calls → Output

**Use Case:** Understanding component interactions

---

### 19. Dry-Run vs Execute Mode

**Location:** Diagrams section
**Type:** Flowchart (Branching)
**Purpose:** Shows difference between modes

**Branches:**
- Dry-run: Simulate → Print preview → No API calls
- Execute: Validate → API calls → Commit changes → Output

**Use Case:** Understanding dry-run behavior

---

## Architecture Design Diagrams (doc/3-design/architecture.md)

### 20. CLI Tool Structure

**Location:** CLI Architecture section
**Type:** Graph (4 subgraphs)
**Purpose:** Shows modular structure of gh-org CLI tool

**Components:**
- Entry Point (gh-org main script)
- Command Layer (cmd/ - check, teams, repos, files, setup)
- Core Logic (pkg/ - config, backend, github, gitea, templates)
- Utilities (internal/ - output, validation)

**Use Case:** Understanding CLI internal architecture

---

### 21. Backend Router Pattern

**Location:** Backend Abstraction Architecture section
**Type:** Graph (4 subgraphs)
**Purpose:** Shows how backend abstraction works

**Layers:**
- Application Layer (Commands)
- Abstraction Layer (Backend Router + Config Detection)
- Implementation Layer (GitHub Backend + Gitea Backend)
- External APIs (gh CLI + tea CLI)

**Use Case:** Understanding multi-platform support

---

### 22. Permission Mapping Architecture

**Location:** Backend Abstraction Architecture section
**Type:** Graph (5 subgraphs)
**Purpose:** Shows how GitHub permissions map to Gitea

**Components:**
- User Configuration (project-config.json)
- Backend Router (dispatches by backend)
- GitHub Backend (direct mapping)
- Gitea Backend (mapping logic)
- Mapped Permissions (pull→read, push→write, admin→admin)

**Use Case:** Understanding permission translation

---

### 23. Backend Detection Flow

**Location:** Backend Abstraction Architecture section
**Type:** Flowchart (Decision tree)
**Purpose:** Shows how backend is selected

**Flow:**
```
Load .env → BACKEND set? → [Yes: Use value | No: Default github]
→ BACKEND == github? → [Yes: Use gh CLI | No: Use tea CLI] → Execute
```

**Use Case:** Troubleshooting backend selection

---

### 24. Backend Implementation Comparison

**Location:** Backend Abstraction Architecture section
**Type:** Graph (3 subgraphs)
**Purpose:** Shows side-by-side implementation of same operation

**Operation:** Create Repository
- Backend router receives request
- GitHub: gh repo view → gh repo create
- Gitea: tea repos list → tea repos create

**Use Case:** Understanding backend differences

---

### 25. CLI Execution Flow

**Location:** CLI Architecture section
**Type:** Sequence diagram
**Purpose:** Shows interaction sequence for CLI commands

**Participants:**
- User
- CLI (gh-org)
- Command Handler
- Backend Router
- GitHub/Gitea API

**Flow:** User command → Parse args → Load config → Route to backend → API call → Response

**Use Case:** Understanding command execution

---

### 26. CLI Command Hierarchy (Architecture)

**Location:** CLI Architecture section
**Type:** Graph (3 subgraphs)
**Purpose:** Shows command and subcommand structure

**Structure:**
```
gh-org → [check, teams, repos, files, setup]
teams → create
repos → create
files → readme/workflow/codeowners
```

**Use Case:** Discovering available commands

---

## Diagram Characteristics

### Color Scheme

**Consistent color coding across all diagrams:**

| Color | Hex | Usage |
|-------|-----|-------|
| Blue | `#e3f2fd` | Start states, inputs |
| Yellow | `#fff3e0` | Processing, config |
| Light Yellow | `#fff9c4` | Decisions, warnings |
| Green | `#c8e6c9` | Success, execution |
| Light Green | `#a5d6a7` | Completion |
| Red | `#ffcdd2` | Errors, issues |
| Purple | `#f3e5f5` | Authentication |
| Orange | `#ffe0b2` | Intermediate states |

### Diagram Types

| Type | Count | Purpose |
|------|-------|---------|
| Flowchart | 14 | Process flows and decisions |
| Graph | 10 | Relationships and structures |
| Sequence | 2 | Component interactions |
| **Total** | **26** | Comprehensive visualization |

### Complexity Levels

| Level | Count | Diagrams |
|-------|-------|----------|
| Simple | 7 | Quick Start, Naming, Workflow 1, Command Hierarchy (x2), Dry-Run, Backend Detection |
| Medium | 12 | Prerequisites, Config, Template Matching, Workflow 2, Permissions, CLI Architecture (x2), File Addition, Data Flow, Backend Router, Permission Mapping, Backend Implementation |
| Complex | 7 | Full Workflow, Decision Tree, Troubleshooting, Best Practices, CLI Setup Workflow, Sequence Diagrams (x2) |

---

## Usage Guidelines

### For Documentation Writers

**Adding new diagrams:**
1. Use mermaid syntax
2. Follow color scheme
3. Keep complexity appropriate
4. Add to this index

**Best practices:**
- Limit to 10-15 nodes for readability
- Use consistent node shapes
- Add descriptive labels
- Test rendering on GitHub

### For Users

**Reading diagrams:**
- Blue nodes = starting points
- Yellow nodes = actions/processing
- Green nodes = successful outcomes
- Red nodes = errors/problems
- Diamond shapes = decisions

**Navigation:**
- Follow arrows for flow
- Dotted lines = optional/metadata
- Subgraphs = grouped components

---

## Rendering

### GitHub

All mermaid diagrams render automatically on GitHub:
```
https://github.com/phdsystems/project-management-automation/blob/main/docs/user-guide.md
```

### Local

**VS Code:** Install "Markdown Preview Mermaid Support" extension

**Command line:**
```bash
# Install mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Generate PNG
mmdc -i docs/user-guide.md -o diagrams/
```

### Online

Paste mermaid code at:
- https://mermaid.live/
- https://mermaid.ink/

---

## Benefits

### For Users

✅ **Visual learners** - Understand flows without reading prose
✅ **Quick reference** - Scan diagrams for overview
✅ **Troubleshooting** - Follow decision trees to solutions
✅ **Planning** - Visualize before executing

### For Documentation

✅ **Clarity** - Complex processes shown simply
✅ **Engagement** - Visual breaks in text
✅ **Completeness** - Multiple learning styles supported
✅ **Maintenance** - Diagrams update with code

---

## Metrics

| Metric | Value |
|--------|-------|
| Total diagrams | 26 |
| User Guide diagrams | 12 |
| CLI Guide diagrams | 7 |
| Architecture diagrams | 7 |
| Total nodes | ~400 |
| Total edges | ~450 |
| Lines of mermaid code | ~1100 |
| Sections with diagrams | 25 |
| Coverage | 98% of major sections |

---

## Future Enhancements

**Potential additions:**

- [ ] API call sequence diagram
- [ ] Error recovery flowchart
- [ ] Team membership diagram
- [ ] Multi-environment setup
- [ ] Rollback procedure
- [ ] CI/CD integration diagram
- [ ] Security workflow
- [ ] Performance optimization flow

---

**For more diagrams, see:**
- Main README: `../README.md` (Architecture Overview, Workflow Diagram, etc.)
- User Guide: `user-guide.md` (12 Makefile workflow diagrams)
- CLI Guide: `cli-guide.md` (7 CLI-specific diagrams)
- Architecture Design: `3-design/architecture.md` (7 backend abstraction and CLI structure diagrams)
- CI Parallelization: `ci-parallelization-strategies.md` (3 execution models)

*Last Updated: 2025-10-27*
