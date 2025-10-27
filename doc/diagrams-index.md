# Mermaid Diagrams Index

**Locations:** `doc/user-guide.md`, `doc/cli-guide.md`
**Total Diagrams:** 18 (11 in User Guide + 7 in CLI Guide)
**Last Updated:** 2025-10-27

## Overview

The documentation includes 18 mermaid diagrams across two main guides:
- **User Guide** (11 diagrams) - Makefile workflows, configurations, and decision trees
- **CLI Guide** (7 diagrams) - CLI architecture, command flows, and comparisons

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
| Flowchart | 13 | Process flows and decisions |
| Graph | 5 | Relationships and structures |
| Sequence | 1 | Component interactions |
| **Total** | **19** | Comprehensive visualization |

### Complexity Levels

| Level | Count | Diagrams |
|-------|-------|----------|
| Simple | 5 | Quick Start, Naming, Workflow 1, Command Hierarchy, Dry-Run |
| Medium | 8 | Prerequisites, Config, Template Matching, Workflow 2, Permissions, CLI Architecture, File Addition, Data Flow |
| Complex | 6 | Full Workflow, Decision Tree, Troubleshooting, Best Practices, CLI Setup Workflow, Sequence Diagram |

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
| Total diagrams | 19 |
| User Guide diagrams | 12 |
| CLI Guide diagrams | 7 |
| Total nodes | ~280 |
| Total edges | ~320 |
| Lines of mermaid code | ~750 |
| Sections with diagrams | 18 |
| Coverage | 95% of major sections |

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
- CLI Guide: `cli-guide.md` (7 CLI-specific diagrams)
- User Guide: `user-guide.md` (12 Makefile workflow diagrams)
- CI Parallelization: `ci-parallelization-strategies.md` (3 execution models)

*Last Updated: 2025-10-27*
