# Architecture Design - GitHub Organization Automation

**Date:** 2025-10-27
**Version:** 2.0.0

## TL;DR

**Architecture**: Makefile-based automation orchestrating GitHub CLI operations with template processing. **Key patterns**: Configuration-driven → Idempotent operations → Template matching by convention → Progressive execution (teams → repos → files). **Critical design**: Stateless execution, no database, relies entirely on GitHub API as source of truth.

---

## Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Component Architecture](#component-architecture)
- [Data Flow](#data-flow)
- [Technology Stack](#technology-stack)
- [Design Patterns](#design-patterns)
- [Deployment Architecture](#deployment-architecture)
- [Scalability](#scalability)
- [Security Architecture](#security-architecture)

---

## Overview

### System Purpose

Automate the creation and configuration of GitHub teams, repositories, and standard files across multiple projects within a GitHub Organization.

### Architecture Goals

1. **Simplicity** - Single Makefile, no complex dependencies
2. **Idempotency** - Safe to run multiple times
3. **Transparency** - Clear, readable automation steps
4. **Flexibility** - Configuration-driven, easy to customize
5. **Reliability** - Fail-fast with clear error messages

### Architecture Principles

- **Configuration over Code** - JSON config drives all operations
- **Convention over Configuration** - Template matching by naming
- **Stateless Operation** - GitHub API is source of truth
- **Progressive Enhancement** - Build incrementally (teams → repos → files)
- **Fail-Fast** - Validate early, exit on error

---

## System Architecture

### High-Level Architecture

```mermaid
C4Context
    title System Context - GitHub Organization Automation

    Person(user, "DevOps Engineer", "Configures and runs automation")

    System(automation, "GitHub Org Automation", "Makefile-based automation system")

    System_Ext(github, "GitHub API", "Teams, repos, and file operations")
    System_Ext(templates, "Template System", "README, workflows, CODEOWNERS")

    Rel(user, automation, "Configures and executes", "CLI")
    Rel(automation, github, "Creates and manages", "GitHub CLI / REST API")
    Rel(automation, templates, "Reads and applies", "File system")

    UpdateRelStyle(user, automation, $offsetX="-40", $offsetY="-30")
    UpdateRelStyle(automation, github, $offsetX="0", $offsetY="-30")
```

### Layered Architecture

```mermaid
graph TB
    subgraph "User Interface Layer"
        CLI[Command Line Interface]
        DryRun[Dry-Run Mode]
    end

    subgraph "Orchestration Layer"
        Makefile[Makefile Engine]
        Targets[Make Targets]
        Dependencies[Target Dependencies]
    end

    subgraph "Processing Layer"
        ConfigParser[JSON Config Parser - jq]
        TemplateEngine[Template Matcher]
        Validator[Prerequisites Validator]
    end

    subgraph "Integration Layer"
        GitHubCLI[GitHub CLI - gh]
        GitOps[Git Operations]
        APIWrapper[API Wrapper Functions]
    end

    subgraph "External Systems"
        GitHub[GitHub API]
        FileSystem[Template Files]
    end

    CLI --> Makefile
    DryRun --> Makefile
    Makefile --> Targets
    Targets --> Dependencies

    Dependencies --> ConfigParser
    Dependencies --> TemplateEngine
    Dependencies --> Validator

    ConfigParser --> GitHubCLI
    TemplateEngine --> GitOps
    Validator --> GitHubCLI

    GitHubCLI --> GitHub
    GitOps --> GitHub
    APIWrapper --> GitHub

    TemplateEngine --> FileSystem

    style CLI fill:#e3f2fd
    style Makefile fill:#fff3e0
    style ConfigParser fill:#f3e5f5
    style GitHubCLI fill:#c8e6c9
    style GitHub fill:#ffecb3
```

---

## Component Architecture

### Component Diagram

```mermaid
graph TB
    subgraph "Configuration Components"
        ENV[.env File]
        CONFIG[project-config.json]
        TEMPLATES[templates/]
    end

    subgraph "Core Components"
        MAKEFILE[Makefile]
        PREREQS[Prerequisites Check]
        TEAMS[Teams Creator]
        REPOS[Repos Creator]
        FILES[File Applier]
    end

    subgraph "Utility Components"
        JQ[jq JSON Parser]
        GH[GitHub CLI]
        GIT[Git Client]
    end

    subgraph "External Services"
        GITHUB_API[GitHub REST API]
        GITHUB_REPOS[Repository Storage]
    end

    ENV --> MAKEFILE
    CONFIG --> MAKEFILE
    TEMPLATES --> FILES

    MAKEFILE --> PREREQS
    PREREQS --> TEAMS
    TEAMS --> REPOS
    REPOS --> FILES

    TEAMS --> JQ
    REPOS --> JQ
    FILES --> GIT

    JQ --> CONFIG
    GH --> GITHUB_API
    GIT --> GITHUB_REPOS

    style MAKEFILE fill:#e3f2fd,stroke:#1976d2,stroke-width:3px
    style CONFIG fill:#fff3e0
    style TEMPLATES fill:#f3e5f5
    style GITHUB_API fill:#c8e6c9
```

### Component Responsibilities

| Component | Responsibility | Technology |
|-----------|---------------|------------|
| **Makefile** | Orchestration, workflow control | GNU Make 4.x |
| **Prerequisites Check** | Validate tools, files, auth | Bash + gh CLI |
| **Teams Creator** | Create/verify GitHub teams | gh api + jq |
| **Repos Creator** | Create repos, assign teams | gh repo + gh api |
| **File Applier** | Clone, commit, push templates | git + bash |
| **JSON Parser** | Extract config values | jq 1.6+ |
| **GitHub CLI** | API abstraction | gh CLI 2.x |
| **Git Client** | Repository operations | git 2.x |

---

## Data Flow

### Overall Data Flow

```mermaid
flowchart LR
    subgraph Input["Input Sources"]
        A1[.env]
        A2[project-config.json]
        A3[templates/]
    end

    subgraph Processing["Processing Pipeline"]
        B1[Load Environment]
        B2[Parse Configuration]
        B3[Match Templates]
        B4[Validate Prerequisites]
    end

    subgraph Operations["Operations"]
        C1[Create Teams]
        C2[Create Repositories]
        C3[Assign Permissions]
        C4[Apply Templates]
    end

    subgraph Output["Output"]
        D1[GitHub Teams]
        D2[GitHub Repositories]
        D3[Committed Files]
    end

    A1 --> B1
    A2 --> B2
    A3 --> B3

    B1 --> B4
    B2 --> B4
    B3 --> B4

    B4 --> C1
    C1 --> C2
    C2 --> C3
    C3 --> C4

    C1 --> D1
    C2 --> D2
    C4 --> D3

    style Input fill:#e3f2fd
    style Processing fill:#fff3e0
    style Operations fill:#c8e6c9
    style Output fill:#a5d6a7
```

### Configuration Data Flow

```mermaid
sequenceDiagram
    participant User
    participant Makefile
    participant jq
    participant Config as project-config.json

    User->>Makefile: make all
    Makefile->>Config: Read file
    Config-->>Makefile: JSON data

    Makefile->>jq: Parse .teams[]
    jq-->>Makefile: ["team1", "team2"]

    Makefile->>jq: Parse .projects[]
    jq-->>Makefile: [{name, repos}]

    Makefile->>jq: Parse .projects[].repos[]
    jq-->>Makefile: [{name, team, permission}]

    Note over Makefile: Process each team/repo
```

---

## Technology Stack

### Core Technologies

```mermaid
graph TB
    subgraph "Development Tools"
        MAKE[GNU Make 4.x]
        BASH[Bash 4.0+]
        JQ[jq 1.6+]
    end

    subgraph "Integration Tools"
        GH[GitHub CLI 2.x]
        GIT[Git 2.x]
    end

    subgraph "Configuration"
        JSON[JSON Config]
        ENV[Environment Variables]
        YAML[YAML Templates]
    end

    subgraph "External Services"
        API[GitHub REST API]
        AUTH[GitHub OAuth]
    end

    MAKE --> BASH
    BASH --> JQ
    BASH --> GH
    BASH --> GIT

    JQ --> JSON
    MAKE --> ENV

    GH --> API
    GH --> AUTH
    GIT --> API

    style MAKE fill:#e3f2fd
    style GH fill:#c8e6c9
    style API fill:#fff3e0
```

### Technology Decisions

| Technology | Chosen | Rationale |
|------------|--------|-----------|
| **Orchestration** | Makefile | Universal, declarative, built-in dependencies |
| **Shell** | Bash | Ubiquitous, powerful, readable |
| **JSON Parser** | jq | Industry standard, powerful queries |
| **GitHub Integration** | gh CLI | Official, well-maintained, auth handled |
| **VCS** | Git | Required for repo operations |
| **Config Format** | JSON | Standard, validated, IDE support |
| **Templates** | Plain text files | Simple, flexible, version controlled |

---

## Design Patterns

### Pattern 1: Configuration-Driven Execution

```mermaid
flowchart TD
    A[JSON Configuration] --> B{Parser}
    B --> C[Teams List]
    B --> D[Projects List]

    C --> E[Create Teams]
    D --> F[Create Repos]

    E --> G[GitHub API]
    F --> G

    style A fill:#e3f2fd
    style B fill:#fff3e0
    style G fill:#c8e6c9
```

**Benefits:**
- Single source of truth
- Easy to version control
- Declarative intent
- No code changes needed

### Pattern 2: Idempotent Operations

```mermaid
flowchart TD
    A[Operation Request] --> B{Resource Exists?}
    B -->|Yes| C[Skip - No Change]
    B -->|No| D[Create Resource]

    C --> E[Continue]
    D --> E

    style B fill:#fff9c4
    style C fill:#fff3e0
    style D fill:#c8e6c9
```

**Implementation:**
- Check existence before creation
- Safe to retry
- No side effects on re-run

### Pattern 3: Convention over Configuration

```mermaid
flowchart LR
    A[Repo Name: 'frontend'] --> B{Extract Role}
    B --> C[templates/README-frontend.md]
    B --> D[templates/workflow-frontend.yml]

    C --> E[Matched by Convention]
    D --> E

    style A fill:#e3f2fd
    style E fill:#c8e6c9
```

**Convention Rules:**
- Repo role → Template filename
- `project-{name}-{role}` naming
- Automatic template selection

### Pattern 4: Progressive Enhancement

```mermaid
flowchart TD
    A[Stage 1: Teams] --> B[Stage 2: Repos]
    B --> C[Stage 3: Permissions]
    C --> D[Stage 4: READMEs]
    D --> E[Stage 5: Workflows]
    E --> F[Stage 6: CODEOWNERS]

    style A fill:#e3f2fd
    style C fill:#fff3e0
    style F fill:#c8e6c9
```

**Benefits:**
- Clear progression
- Easy to debug
- Can run stages individually
- Fail at any stage, recover easily

---

## Deployment Architecture

### Local Execution Environment

```mermaid
graph TB
    subgraph "Developer Machine"
        DIR[Project Directory]
        ENV[.env File]
        CONFIG[Config Files]
        MAKE[Make Command]
    end

    subgraph "System Dependencies"
        GH[GitHub CLI]
        JQ[jq]
        GIT[Git]
        BASH[Bash Shell]
    end

    subgraph "Network"
        API[GitHub API]
        REPOS[Git Repositories]
    end

    DIR --> MAKE
    ENV --> MAKE
    CONFIG --> MAKE

    MAKE --> GH
    MAKE --> JQ
    MAKE --> GIT
    MAKE --> BASH

    GH --> API
    GIT --> REPOS

    style DIR fill:#e3f2fd
    style MAKE fill:#fff3e0
    style API fill:#c8e6c9
```

### CI/CD Execution

```mermaid
graph TB
    subgraph "GitHub Actions Runner"
        CHECKOUT[Checkout Code]
        SETUP[Setup Dependencies]
        TEST[Run Tests]
        EXECUTE[Execute Automation]
    end

    subgraph "Artifacts"
        LOGS[Execution Logs]
        REPORTS[Test Reports]
    end

    subgraph "GitHub"
        API[GitHub API]
        REPOS[Repositories]
    end

    CHECKOUT --> SETUP
    SETUP --> TEST
    TEST --> EXECUTE

    EXECUTE --> LOGS
    EXECUTE --> REPORTS

    EXECUTE --> API
    EXECUTE --> REPOS

    style CHECKOUT fill:#e3f2fd
    style TEST fill:#fff3e0
    style EXECUTE fill:#c8e6c9
```

---

## Scalability

### Horizontal Scalability

```mermaid
graph TB
    subgraph "Parallel Execution (Future)"
        A[Project 1] --> E1[Executor 1]
        B[Project 2] --> E2[Executor 2]
        C[Project 3] --> E3[Executor 3]
    end

    subgraph "GitHub API"
        API[Rate Limited API]
    end

    E1 --> API
    E2 --> API
    E3 --> API

    style A fill:#e3f2fd
    style B fill:#e3f2fd
    style C fill:#e3f2fd
    style API fill:#ffecb3
```

**Current Limitations:**
- Sequential execution
- No parallelization
- API rate limits (5,000 requests/hour)

**Scale Targets:**
- ✅ 1-10 projects: Excellent performance
- ✅ 10-50 projects: Good performance (~5-10 min)
- ⚠️ 50-100 projects: Acceptable (~15-30 min)
- ❌ 100+ projects: Consider batching

### Performance Optimization

| Operation | Current | Optimized (Future) |
|-----------|---------|-------------------|
| Team creation | Sequential | Parallel |
| Repo creation | Sequential | Parallel |
| File commits | Clone per repo | Sparse checkout |
| API calls | Individual | Batch where possible |

---

## Security Architecture

### Security Layers

```mermaid
graph TB
    subgraph "Authentication"
        A1[GitHub OAuth Token]
        A2[gh CLI Auth]
    end

    subgraph "Authorization"
        B1[Organization Admin]
        B2[Team Permissions]
        B3[Repository Access]
    end

    subgraph "Data Security"
        C1[.env Gitignored]
        C2[No Secrets in Logs]
        C3[HTTPS Only]
    end

    subgraph "API Security"
        D1[Rate Limiting]
        D2[Token Scopes]
        D3[Audit Logs]
    end

    A1 --> A2
    A2 --> B1
    B1 --> B2
    B2 --> B3

    A1 -.-> C1
    B3 -.-> C3
    A1 -.-> D2

    style A1 fill:#ffcdd2
    style C1 fill:#fff9c4
    style D2 fill:#c8e6c9
```

### Security Considerations

**Authentication:**
- ✅ GitHub OAuth via `gh auth login`
- ✅ Token stored securely by gh CLI
- ✅ No hardcoded credentials

**Authorization:**
- ⚠️ Requires Organization admin/owner role
- ✅ Minimum required permissions checked
- ✅ Team permissions configurable

**Data Protection:**
- ✅ `.env` file gitignored
- ✅ No secrets in logs or output
- ✅ All API calls via HTTPS
- ✅ Repository access controlled

**Audit Trail:**
- ✅ GitHub audit logs track all operations
- ✅ Git commits show all changes
- ✅ Make output shows all operations

---

## Architecture Decisions

### ADR-001: Makefile as Orchestration Engine

**Status:** Accepted

**Context:** Need simple, reliable orchestration for automation tasks.

**Decision:** Use GNU Make as the orchestration engine.

**Rationale:**
- Universal availability (pre-installed on most systems)
- Declarative target dependencies
- Built-in dry-run support (`make -n`)
- Simple syntax, easy to read and maintain
- No additional runtime dependencies

**Consequences:**
- ✅ Simple deployment (just clone and run)
- ✅ Easy to understand for most developers
- ❌ Limited to sequential execution
- ❌ Bash scripting limitations

---

### ADR-002: GitHub CLI for API Integration

**Status:** Accepted

**Context:** Need to interact with GitHub API for teams and repos.

**Decision:** Use GitHub CLI (`gh`) as the primary API interface.

**Rationale:**
- Official GitHub tool
- Handles authentication automatically
- Simpler than raw REST API calls
- Well-maintained and documented
- Built-in JSON formatting

**Consequences:**
- ✅ Simplified authentication flow
- ✅ Less code to maintain
- ✅ Future API changes handled by gh team
- ❌ Dependency on external tool
- ❌ Must follow gh CLI release cycle

---

### ADR-003: JSON for Configuration

**Status:** Accepted

**Context:** Need human-readable, machine-parseable configuration format.

**Decision:** Use JSON for `project-config.json`.

**Rationale:**
- Standard format with wide support
- Easy to validate (schema validation possible)
- Excellent IDE support (autocomplete, validation)
- Native GitHub support (syntax highlighting)
- `jq` is powerful and widely available

**Consequences:**
- ✅ Easy to validate and parse
- ✅ Good tooling support
- ❌ No comments support
- ❌ Strict syntax (trailing commas not allowed)

---

### ADR-004: Idempotent Operations

**Status:** Accepted

**Context:** Users may need to run automation multiple times.

**Decision:** All operations must be idempotent (safe to retry).

**Rationale:**
- Recovery from failures
- Ability to add new resources to existing setup
- No fear of re-running automation
- Consistent state regardless of how many times run

**Consequences:**
- ✅ Safe to retry on failure
- ✅ Easy to add resources incrementally
- ✅ Predictable behavior
- ❌ Requires existence checks before creation
- ❌ Slightly slower due to checks

---

### ADR-005: Template Matching by Convention

**Status:** Accepted

**Context:** Need to apply correct template to each repository.

**Decision:** Match templates by repository role name (convention).

**Rationale:**
- Simple, predictable matching
- No additional configuration needed
- Easy to understand and debug
- Scales well with new templates

**Consequences:**
- ✅ Zero configuration for template matching
- ✅ Predictable behavior
- ✅ Easy to add new templates
- ❌ Template files must follow naming convention
- ❌ Less flexible than explicit mapping

---

## Future Architecture Enhancements

### Planned Improvements

1. **Parallel Execution**
   - Execute multiple projects concurrently
   - Reduce total execution time
   - Respect API rate limits

2. **Caching Layer**
   - Cache GitHub API responses
   - Reduce redundant API calls
   - Improve performance

3. **State Management**
   - Track what has been created
   - Enable rollback functionality
   - Support diff operations

4. **Plugin System**
   - Custom template processors
   - Extensible validation
   - Custom workflow hooks

5. **Web UI (Optional)**
   - Visual configuration builder
   - Real-time progress monitoring
   - Historical execution logs

---

## References

- **GitHub API:** https://docs.github.com/en/rest
- **GitHub CLI:** https://cli.github.com/manual/
- **GNU Make:** https://www.gnu.org/software/make/manual/
- **jq Manual:** https://stedolan.github.io/jq/manual/
- **C4 Model:** https://c4model.com/

---

*Last Updated: 2025-10-27*
*Version: 2.0.0*
