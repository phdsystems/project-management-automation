# Mermaid Diagrams Index

**Location:** `docs/user-guide.md`
**Total Diagrams:** 11
**Last Updated:** 2025-10-27

## Overview

The User Guide includes 11 mermaid diagrams to visualize workflows, configurations, and decision trees.

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
| Flowchart | 9 | Process flows and decisions |
| Graph | 3 | Relationships and structures |
| **Total** | **12** | Comprehensive visualization |

### Complexity Levels

| Level | Count | Diagrams |
|-------|-------|----------|
| Simple | 3 | Quick Start, Naming, Workflow 1 |
| Medium | 5 | Prerequisites, Config, Template Matching, Workflow 2, Permissions |
| Complex | 4 | Full Workflow, Decision Tree, Troubleshooting, Best Practices |

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
| Total diagrams | 12 |
| Total nodes | ~150 |
| Total edges | ~180 |
| Lines of mermaid code | ~370 |
| Sections with diagrams | 11 |
| Coverage | 92% of major sections |

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
- CI Parallelization: `ci-parallelization-strategies.md` (3 execution models)

*Last Updated: 2025-10-27*
