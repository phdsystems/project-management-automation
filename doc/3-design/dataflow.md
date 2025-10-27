# Data Flow Design - GitHub Organization Automation

**Date:** 2025-10-27
**Version:** 1.0

---

## Overview

This document describes how data flows through the GitHub Organization Automation system, from configuration files to GitHub API operations. It covers configuration loading, parsing, transformation, and execution flows.

---

## High-Level Data Flow

```mermaid
flowchart TB
    subgraph "Input Layer"
        EnvFile[.env File]
        ConfigFile[project-config.json]
        Templates[Template Files]
    end

    subgraph "Processing Layer"
        EnvVars[Environment Variables]
        JSONParse[Parsed Configuration]
        Validation[Validated Data]
    end

    subgraph "Transformation Layer"
        TeamsList[Teams List]
        ReposList[Repositories List]
        FilesList[Files to Create]
    end

    subgraph "Execution Layer"
        APIRequests[GitHub API Requests]
        APIResponses[API Responses]
    end

    subgraph "Output Layer"
        Teams[GitHub Teams]
        Repos[GitHub Repositories]
        Files[Repository Files]
    end

    EnvFile --> EnvVars
    ConfigFile --> JSONParse
    Templates --> FilesList

    EnvVars --> Validation
    JSONParse --> Validation

    Validation --> TeamsList
    Validation --> ReposList

    TeamsList --> APIRequests
    ReposList --> APIRequests
    FilesList --> APIRequests

    APIRequests --> APIResponses

    APIResponses --> Teams
    APIResponses --> Repos
    APIResponses --> Files

    style EnvFile fill:#e3f2fd
    style ConfigFile fill:#e3f2fd
    style Templates fill:#e3f2fd
    style Validation fill:#fff9c4
    style APIRequests fill:#ffe0b2
    style Teams fill:#c8e6c9
    style Repos fill:#c8e6c9
    style Files fill:#c8e6c9
```

---

## 1. Configuration Data Flow

### Environment Variables Flow

```mermaid
sequenceDiagram
    participant User
    participant EnvFile as .env File
    participant Makefile
    participant Shell as Shell Environment
    participant Targets as Makefile Targets

    User->>EnvFile: Create/Edit .env
    Note over EnvFile: ORG=phdsystems<br/>CONFIG=project-config.json<br/>DRY_RUN=0

    User->>Makefile: Execute make target
    Makefile->>EnvFile: Read file
    EnvFile-->>Makefile: Key-value pairs

    Makefile->>Makefile: Parse and export
    Makefile->>Shell: Export variables
    Shell-->>Targets: Variables available

    Targets->>Targets: Use $(ORG), $(CONFIG), etc.
    Targets->>Targets: Execute with env vars
```

**Data Structure:**
```bash
# Input (.env file)
ORG=phdsystems
CONFIG=project-config.json
DEFAULT_BRANCH=main
DRY_RUN=0
VERBOSE=0

# Output (Environment Variables)
export ORG="phdsystems"
export CONFIG="project-config.json"
export DEFAULT_BRANCH="main"
export DRY_RUN="0"
export VERBOSE="0"
```

### JSON Configuration Flow

```mermaid
flowchart TB
    Start[project-config.json] --> Read[Read File]
    Read --> Validate{Valid JSON?}

    Validate -->|No| Error1[ERROR: Invalid JSON]
    Validate -->|Yes| ParseTeams[Parse Teams Array]

    ParseTeams --> ExtractTeams[Extract Team Names]
    ExtractTeams --> TeamsList["teams = ['team1', 'team2']"]

    ParseTeams --> ParseProjects[Parse Projects Array]
    ParseProjects --> ForEachProject{For Each Project}

    ForEachProject --> ExtractProject[Extract Project Name]
    ExtractProject --> ExtractRepos[Extract Repos Array]

    ExtractRepos --> ForEachRepo{For Each Repo}
    ForEachRepo --> BuildRepoData[Build Repo Data Object]

    BuildRepoData --> RepoData["repo = {<br/>name: 'frontend',<br/>team: 'team1',<br/>permission: 'push',<br/>full_name: 'project-alpha-frontend'<br/>}"]

    RepoData --> ReposList[Repositories List]

    TeamsList --> ValidateRefs[Validate Team References]
    ReposList --> ValidateRefs

    ValidateRefs --> |All teams exist| Valid[✅ Valid Configuration]
    ValidateRefs --> |Missing team| Error2[❌ ERROR: Invalid team reference]

    Error1 --> Exit[Exit 1]
    Error2 --> Exit
    Valid --> Continue[Continue Execution]

    style Start fill:#e3f2fd
    style Valid fill:#c8e6c9
    style Continue fill:#a5d6a7
    style Error1 fill:#ffcdd2
    style Error2 fill:#ffcdd2
```

**Data Transformations:**

```json
// Input: project-config.json
{
  "teams": ["frontend-team", "backend-team"],
  "projects": [{
    "name": "alpha",
    "repos": [{
      "name": "frontend",
      "team": "frontend-team",
      "permission": "push"
    }]
  }]
}

// Output: Extracted teams list
teams = ["frontend-team", "backend-team"]

// Output: Extracted repos with computed names
repos = [{
  "project": "alpha",
  "name": "frontend",
  "full_name": "project-alpha-frontend",
  "team": "frontend-team",
  "permission": "push",
  "template_readme": "templates/README-frontend.md",
  "template_workflow": "templates/workflow-frontend.yml"
}]
```

---

## 2. Execution Data Flow

### Team Creation Flow

```mermaid
sequenceDiagram
    participant Config as Configuration
    participant TeamMgr as Team Manager
    participant GH as GitHub CLI
    participant API as GitHub API
    participant Org as GitHub Organization

    Config->>TeamMgr: teams = ['team1', 'team2']
    TeamMgr->>TeamMgr: For each team

    loop For Each Team
        TeamMgr->>GH: Check team exists
        GH->>API: GET /orgs/phdsystems/teams/team1
        API-->>GH: Response

        alt Team exists (200)
            GH-->>TeamMgr: Team data
            TeamMgr->>TeamMgr: Log: Already exists
        else Team not found (404)
            GH-->>TeamMgr: 404 Not Found
            TeamMgr->>TeamMgr: Check DRY_RUN

            alt DRY_RUN = 1
                TeamMgr->>TeamMgr: Log: Would create
            else DRY_RUN = 0
                TeamMgr->>GH: Create team
                GH->>API: POST /orgs/phdsystems/teams
                Note over API: Request body:<br/>{name: "team1", privacy: "closed"}
                API->>Org: Create team resource
                Org-->>API: Team created
                API-->>GH: 201 Created + team data
                GH-->>TeamMgr: Success
                TeamMgr->>TeamMgr: Log: Created
            end
        end
    end

    TeamMgr-->>Config: All teams processed
```

**Data at Each Stage:**

1. **Input:**
```bash
teams = ["frontend-team", "backend-team"]
ORG = "phdsystems"
DRY_RUN = "0"
```

2. **Existence Check:**
```bash
# API Request
GET /orgs/phdsystems/teams/frontend-team

# API Response (exists)
{
  "id": 12345,
  "name": "frontend-team",
  "slug": "frontend-team",
  "privacy": "closed",
  ...
}

# API Response (not exists)
{
  "message": "Not Found",
  "documentation_url": "..."
}
```

3. **Creation Request:**
```bash
# API Request
POST /orgs/phdsystems/teams
Content-Type: application/json

{
  "name": "frontend-team",
  "privacy": "closed"
}

# API Response
{
  "id": 12345,
  "name": "frontend-team",
  "slug": "frontend-team",
  "privacy": "closed",
  "created_at": "2025-10-27T10:00:00Z",
  ...
}
```

4. **Output:**
```bash
✅ Created team: frontend-team
```

### Repository Creation Flow

```mermaid
flowchart TB
    Start[Repository Data] --> Extract[Extract Properties]

    Extract --> Props["Properties:<br/>- project: alpha<br/>- name: frontend<br/>- team: frontend-team<br/>- permission: push"]

    Props --> BuildName[Build Full Repo Name]
    BuildName --> FullName["full_name = project-alpha-frontend"]

    FullName --> CheckExists{Repo Exists?}
    CheckExists -->|Yes| Skip[Skip Creation]
    CheckExists -->|No| CheckDryRun{DRY_RUN?}

    CheckDryRun -->|Yes| LogDry["Log: Would create"]
    CheckDryRun -->|No| CreateRepo[Create Repository]

    CreateRepo --> RepoPayload["Payload:<br/>{<br/>name: 'project-alpha-frontend',<br/>private: false,<br/>auto_init: true,<br/>default_branch: 'main'<br/>}"]

    RepoPayload --> APICreate[POST /orgs/{org}/repos]
    APICreate --> RepoCreated[Repository Created]

    RepoCreated --> AssignTeam[Assign Team]
    AssignTeam --> TeamPayload["Payload:<br/>{<br/>permission: 'push'<br/>}"]

    TeamPayload --> APIAssign[PUT /orgs/{org}/teams/{team}/repos/{org}/{repo}]
    APIAssign --> TeamAssigned[Team Assigned]

    Skip --> Done[Complete]
    LogDry --> Done
    TeamAssigned --> Done

    style Start fill:#e3f2fd
    style FullName fill:#fff3e0
    style RepoCreated fill:#c8e6c9
    style TeamAssigned fill:#c8e6c9
    style Done fill:#a5d6a7
```

**Data Transformation:**

```bash
# Input from config
{
  "project": "alpha",
  "name": "frontend",
  "team": "frontend-team",
  "permission": "push"
}

# Transformed data
{
  "full_name": "project-alpha-frontend",
  "org": "phdsystems",
  "team": "frontend-team",
  "permission": "push",
  "api_endpoints": {
    "create": "POST /orgs/phdsystems/repos",
    "assign": "PUT /orgs/phdsystems/teams/frontend-team/repos/phdsystems/project-alpha-frontend"
  }
}

# API Request (Create)
POST /orgs/phdsystems/repos
{
  "name": "project-alpha-frontend",
  "private": false,
  "auto_init": true,
  "default_branch": "main"
}

# API Response (Create)
{
  "id": 67890,
  "name": "project-alpha-frontend",
  "full_name": "phdsystems/project-alpha-frontend",
  "private": false,
  "html_url": "https://github.com/phdsystems/project-alpha-frontend",
  "default_branch": "main",
  ...
}

# API Request (Assign Team)
PUT /orgs/phdsystems/teams/frontend-team/repos/phdsystems/project-alpha-frontend
{
  "permission": "push"
}

# API Response (Assign Team)
204 No Content
```

### Template Application Flow

```mermaid
sequenceDiagram
    participant Config as Configuration
    participant TempMgr as Template Manager
    participant FileOps as File Operations
    participant GH as GitHub CLI
    participant API as GitHub API
    participant Repo as Repository

    Config->>TempMgr: repo = {name: 'frontend', ...}
    TempMgr->>TempMgr: Match template

    TempMgr->>TempMgr: template = README-frontend.md
    TempMgr->>FileOps: Read template file
    FileOps-->>TempMgr: File contents (text)

    TempMgr->>TempMgr: Base64 encode
    Note over TempMgr: content = base64(file_contents)

    TempMgr->>GH: Check file exists
    GH->>API: GET /repos/{org}/{repo}/contents/README.md
    API-->>GH: Response

    alt File exists (200)
        GH-->>TempMgr: File data
        TempMgr->>TempMgr: Log: Already exists
    else File not found (404)
        GH-->>TempMgr: 404 Not Found

        alt DRY_RUN = 1
            TempMgr->>TempMgr: Log: Would create
        else DRY_RUN = 0
            TempMgr->>GH: Create file
            GH->>API: PUT /repos/{org}/{repo}/contents/README.md
            Note over API: Request:<br/>{message, content, branch}
            API->>Repo: Create file + commit
            Repo-->>API: File created
            API-->>GH: 201 Created
            GH-->>TempMgr: Success
            TempMgr->>TempMgr: Log: Created
        end
    end
```

**Data Transformation:**

```bash
# Input
repo_name = "frontend"
repo_full = "project-alpha-frontend"
template_file = "templates/README-frontend.md"

# Template file content
"""
# Frontend Application

This is a React 18 + TypeScript + Vite project.

## Setup
npm install
npm run dev
"""

# Base64 encode
content = "IyBGcm9udGVuZCBBcHBsaWNhdGlvbgoKVGhpcyBpcyBhIFJlYWN0IDE4ICsgVHlwZVNjcmlwdCArIFZpdGUgcHJvamVjdC4KCiMjIFNldHVwCm5wbSBpbnN0YWxsCm5wbSBydW4gZGV2"

# API Request
PUT /repos/phdsystems/project-alpha-frontend/contents/README.md
{
  "message": "docs: add README from template",
  "content": "IyBGcm9udGVuZCBBcHBsaWNhdGlvbgoKVGhpcyBpcyBhIFJlYWN0IDE4ICsgVHlwZVNjcmlwdCArIFZpdGUgcHJvamVjdC4KCiMjIFNldHVwCm5wbSBpbnN0YWxsCm5wbSBydW4gZGV2",
  "branch": "main"
}

# API Response
{
  "content": {
    "name": "README.md",
    "path": "README.md",
    "sha": "abc123...",
    "size": 123,
    "url": "...",
    "html_url": "...",
    ...
  },
  "commit": {
    "sha": "def456...",
    "message": "docs: add README from template",
    "author": {...},
    ...
  }
}
```

---

## 3. Data State Transitions

### Configuration State Machine

```mermaid
stateDiagram-v2
    [*] --> Unloaded: System Start
    Unloaded --> Loading: Read files
    Loading --> ParseError: Invalid JSON
    Loading --> Validating: Valid JSON
    Validating --> ValidationError: Missing fields
    Validating --> ValidationError: Invalid references
    Validating --> ValidationError: Invalid permissions
    Validating --> Ready: All validations pass

    ParseError --> [*]: Exit 1
    ValidationError --> [*]: Exit 1
    Ready --> Executing: Start automation

    Executing --> TeamsCreated: Teams created
    TeamsCreated --> ReposCreated: Repos created
    ReposCreated --> FilesAdded: Files added
    FilesAdded --> Complete: All done

    Complete --> [*]: Exit 0
```

### Repository State Machine

```mermaid
stateDiagram-v2
    [*] --> NotExists: Initial State
    NotExists --> Creating: make repos
    Creating --> CreateError: API error
    Creating --> Exists: Created successfully
    NotExists --> Exists: Already exists

    Exists --> AssigningTeam: Assign team
    AssigningTeam --> TeamAssigned: Success
    AssigningTeam --> AssignError: API error

    TeamAssigned --> AddingFiles: Add README/Workflow
    AddingFiles --> FileExists: Already exists
    AddingFiles --> FileAdded: Created
    AddingFiles --> FileError: API error

    FileExists --> Complete
    FileAdded --> Complete
    Complete --> [*]

    CreateError --> [*]: Exit 1
    AssignError --> [*]: Continue
    FileError --> [*]: Continue
```

### Team State Machine

```mermaid
stateDiagram-v2
    [*] --> NotExists: Initial State
    NotExists --> Creating: make teams
    Creating --> CreateError: API error
    Creating --> Exists: Created successfully
    NotExists --> Exists: Already exists (idempotent)

    Exists --> Ready: Available for assignment
    Ready --> Assigned: Assigned to repository
    Assigned --> [*]: Complete

    CreateError --> [*]: Exit 1
```

---

## 4. Data Validation Flow

```mermaid
flowchart TB
    Start[Configuration Data] --> V1{Valid JSON?}
    V1 -->|No| E1[ERROR: JSON syntax]
    V1 -->|Yes| V2{Has teams array?}

    V2 -->|No| E2[ERROR: Missing teams]
    V2 -->|Yes| V3{Teams array not empty?}

    V3 -->|No| E3[ERROR: Empty teams]
    V3 -->|Yes| V4{Has projects array?}

    V4 -->|No| E4[ERROR: Missing projects]
    V4 -->|Yes| V5{Projects array not empty?}

    V5 -->|No| E5[ERROR: Empty projects]
    V5 -->|Yes| V6{All projects have repos?}

    V6 -->|No| E6[ERROR: Missing repos]
    V6 -->|Yes| V7{All repo teams defined?}

    V7 -->|No| E7[ERROR: Invalid team ref]
    V7 -->|Yes| V8{All permissions valid?}

    V8 -->|No| E8[ERROR: Invalid permission]
    V8 -->|Yes| V9{All names valid format?}

    V9 -->|No| E9[ERROR: Invalid name]
    V9 -->|Yes| Success[✅ Valid Configuration]

    E1 --> Exit[Exit 1]
    E2 --> Exit
    E3 --> Exit
    E4 --> Exit
    E5 --> Exit
    E6 --> Exit
    E7 --> Exit
    E8 --> Exit
    E9 --> Exit

    Success --> DataReady[Data Ready for Execution]
    DataReady --> [*]

    style Start fill:#e3f2fd
    style Success fill:#c8e6c9
    style DataReady fill:#a5d6a7
    style E1 fill:#ffcdd2
    style E2 fill:#ffcdd2
    style E3 fill:#ffcdd2
    style E4 fill:#ffcdd2
    style E5 fill:#ffcdd2
    style E6 fill:#ffcdd2
    style E7 fill:#ffcdd2
    style E8 fill:#ffcdd2
    style E9 fill:#ffcdd2
```

**Validation Rules:**

| Check | Rule | Error Message |
|-------|------|---------------|
| JSON Syntax | Valid JSON | "Invalid JSON in {file}" |
| Teams Exists | `.teams` field present | "No teams defined" |
| Teams Not Empty | `length > 0` | "Empty teams array" |
| Projects Exists | `.projects` field present | "No projects defined" |
| Projects Not Empty | `length > 0` | "Empty projects array" |
| Repos Exists | Each project has `.repos` | "Missing repos in project {name}" |
| Team References | All `repo.team` in `teams[]` | "Team '{team}' not defined" |
| Permissions Valid | `permission in [pull, push, maintain, triage, admin]` | "Invalid permission: {perm}" |
| Names Format | Matches `^[a-z0-9-]+$` | "Invalid name: {name}" |

---

## 5. API Data Flow

### Request/Response Cycle

```mermaid
sequenceDiagram
    participant App as Application
    participant GH as GitHub CLI
    participant Auth as GitHub Auth
    participant API as GitHub API
    participant Resource as GitHub Resource

    App->>GH: gh api {endpoint}
    GH->>Auth: Check authentication

    alt Not authenticated
        Auth-->>GH: 401 Unauthorized
        GH-->>App: Error: Run gh auth login
    else Authenticated
        Auth-->>GH: Token valid
        GH->>API: HTTP request + Bearer token

        API->>API: Validate request
        API->>API: Check permissions
        API->>API: Check rate limits

        alt Rate limit exceeded
            API-->>GH: 429 Too Many Requests
            GH-->>App: Error: Rate limit
        else Rate limit OK
            alt Resource exists
                API->>Resource: Get/Update resource
                Resource-->>API: Resource data
                API-->>GH: 200 OK + data
                GH-->>App: Success + data
            else Resource not found
                alt GET request
                    API-->>GH: 404 Not Found
                    GH-->>App: Error: Not found
                else POST request
                    API->>Resource: Create resource
                    Resource-->>API: Created
                    API-->>GH: 201 Created + data
                    GH-->>App: Success + data
                end
            end
        end
    end
```

### API Data Structures

#### Team Creation
```bash
# Request
POST /orgs/phdsystems/teams
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "frontend-team",
  "privacy": "closed"
}

# Response (Success)
201 Created
{
  "id": 12345,
  "node_id": "MDQ6VGVhbTEyMzQ1",
  "url": "https://api.github.com/teams/12345",
  "html_url": "https://github.com/orgs/phdsystems/teams/frontend-team",
  "name": "frontend-team",
  "slug": "frontend-team",
  "description": "",
  "privacy": "closed",
  "permission": "pull",
  "members_url": "...",
  "repositories_url": "...",
  "created_at": "2025-10-27T10:00:00Z",
  "updated_at": "2025-10-27T10:00:00Z"
}

# Response (Error - Already Exists)
422 Unprocessable Entity
{
  "message": "Validation Failed",
  "errors": [
    {
      "resource": "Team",
      "code": "already_exists",
      "field": "name"
    }
  ]
}
```

#### Repository Creation
```bash
# Request
POST /orgs/phdsystems/repos
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "project-alpha-frontend",
  "description": "Frontend application for alpha project",
  "private": false,
  "auto_init": true,
  "default_branch": "main"
}

# Response (Success)
201 Created
{
  "id": 67890,
  "node_id": "MDEwOlJlcG9zaXRvcnk2Nzg5MA==",
  "name": "project-alpha-frontend",
  "full_name": "phdsystems/project-alpha-frontend",
  "private": false,
  "owner": {...},
  "html_url": "https://github.com/phdsystems/project-alpha-frontend",
  "description": "Frontend application for alpha project",
  "fork": false,
  "url": "https://api.github.com/repos/phdsystems/project-alpha-frontend",
  "created_at": "2025-10-27T10:00:00Z",
  "updated_at": "2025-10-27T10:00:00Z",
  "pushed_at": "2025-10-27T10:00:00Z",
  "size": 0,
  "stargazers_count": 0,
  "watchers_count": 0,
  "language": null,
  "has_issues": true,
  "has_projects": true,
  "has_downloads": true,
  "has_wiki": false,
  "has_pages": false,
  "default_branch": "main",
  ...
}
```

#### Team Assignment
```bash
# Request
PUT /orgs/phdsystems/teams/frontend-team/repos/phdsystems/project-alpha-frontend
Authorization: Bearer {token}
Content-Type: application/json

{
  "permission": "push"
}

# Response (Success)
204 No Content

# No response body for 204
```

#### File Creation
```bash
# Request
PUT /repos/phdsystems/project-alpha-frontend/contents/README.md
Authorization: Bearer {token}
Content-Type: application/json

{
  "message": "docs: add README from template",
  "content": "IyBGcm9udGVuZCBBcHBsaWNhdGlvbgo...",
  "branch": "main"
}

# Response (Success)
201 Created
{
  "content": {
    "name": "README.md",
    "path": "README.md",
    "sha": "abc123def456",
    "size": 123,
    "url": "https://api.github.com/repos/phdsystems/project-alpha-frontend/contents/README.md",
    "html_url": "https://github.com/phdsystems/project-alpha-frontend/blob/main/README.md",
    "git_url": "...",
    "download_url": "...",
    "type": "file",
    "_links": {...}
  },
  "commit": {
    "sha": "def456abc123",
    "node_id": "...",
    "url": "...",
    "html_url": "...",
    "author": {
      "name": "username",
      "email": "user@example.com",
      "date": "2025-10-27T10:00:00Z"
    },
    "committer": {...},
    "tree": {...},
    "message": "docs: add README from template",
    "parents": [...]
  }
}
```

---

## 6. Error Data Flow

```mermaid
flowchart TB
    Start[Operation Start] --> Execute[Execute Action]
    Execute --> Result{Result?}

    Result -->|Success| Log1[Log Success]
    Result -->|Error| Classify{Error Type?}

    Classify -->|404| Handle404[Handle Not Found]
    Classify -->|403| Handle403[Handle Forbidden]
    Classify -->|422| Handle422[Handle Validation]
    Classify -->|429| Handle429[Handle Rate Limit]
    Classify -->|Other| HandleOther[Handle Generic Error]

    Handle404 --> Critical404{Critical?}
    Critical404 -->|Yes| Exit1[Exit 1]
    Critical404 -->|No| Log2[Log Warning]

    Handle403 --> Exit2[Exit 1]
    Note right of Exit2: Always critical

    Handle422 --> Critical422{Critical?}
    Critical422 -->|Yes| Exit3[Exit 1]
    Critical422 -->|No| Log3[Log Warning]

    Handle429 --> Wait[Wait + Retry]
    Wait --> RetryCount{Retries left?}
    RetryCount -->|Yes| Execute
    RetryCount -->|No| Exit4[Exit 1]

    HandleOther --> Exit5[Exit 1]

    Log1 --> Continue
    Log2 --> Continue
    Log3 --> Continue
    Continue[Continue Execution]

    style Start fill:#e3f2fd
    style Log1 fill:#c8e6c9
    style Continue fill:#a5d6a7
    style Exit1 fill:#ffcdd2
    style Exit2 fill:#ffcdd2
    style Exit3 fill:#ffcdd2
    style Exit4 fill:#ffcdd2
    style Exit5 fill:#ffcdd2
```

**Error Data Structures:**

```bash
# 404 Not Found
{
  "message": "Not Found",
  "documentation_url": "https://docs.github.com/rest/..."
}

# 403 Forbidden
{
  "message": "Forbidden",
  "documentation_url": "https://docs.github.com/rest/..."
}

# 422 Validation Failed
{
  "message": "Validation Failed",
  "errors": [
    {
      "resource": "Team",
      "code": "already_exists",
      "field": "name"
    }
  ],
  "documentation_url": "https://docs.github.com/rest/..."
}

# 429 Rate Limit
{
  "message": "API rate limit exceeded",
  "documentation_url": "https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting"
}
```

---

## 7. Complete Execution Data Flow

```mermaid
flowchart TB
    Start[Start: make all] --> LoadEnv[Load .env]
    LoadEnv --> LoadConfig[Load project-config.json]
    LoadConfig --> Validate[Validate Configuration]

    Validate --> Prereq[Check Prerequisites]
    Prereq --> PrereqOK{All OK?}
    PrereqOK -->|No| ExitError[Exit 1]
    PrereqOK -->|Yes| ExtractTeams[Extract Teams Data]

    ExtractTeams --> TeamLoop[For Each Team]
    TeamLoop --> TeamExists{Team Exists?}
    TeamExists -->|Yes| TeamSkip[Skip: Already exists]
    TeamExists -->|No| TeamCreate[Create Team]
    TeamCreate --> TeamDone{More Teams?}
    TeamSkip --> TeamDone
    TeamDone -->|Yes| TeamLoop
    TeamDone -->|No| ExtractRepos[Extract Repos Data]

    ExtractRepos --> RepoLoop[For Each Repo]
    RepoLoop --> BuildRepoName[Build Full Repo Name]
    BuildRepoName --> RepoExists{Repo Exists?}
    RepoExists -->|Yes| RepoSkip[Skip: Already exists]
    RepoExists -->|No| RepoCreate[Create Repo]
    RepoCreate --> AssignTeam[Assign Team]
    AssignTeam --> RepoDone{More Repos?}
    RepoSkip --> RepoDone
    RepoDone -->|Yes| RepoLoop
    RepoDone -->|No| FileLoop[For Each Repo + File Type]

    FileLoop --> MatchTemplate[Match Template]
    MatchTemplate --> TemplateExists{Template Exists?}
    TemplateExists -->|No| FileSkip[Skip: No template]
    TemplateExists -->|Yes| FileExists{File Exists?}
    FileExists -->|Yes| FileSkipExists[Skip: Already exists]
    FileExists -->|No| ReadTemplate[Read Template File]
    ReadTemplate --> EncodeBase64[Base64 Encode]
    EncodeBase64 --> CreateFile[Create File via API]
    CreateFile --> FileDone{More Files?}
    FileSkip --> FileDone
    FileSkipExists --> FileDone
    FileDone -->|Yes| FileLoop
    FileDone -->|No| Success[✅ Complete]

    Success --> Exit0[Exit 0]

    style Start fill:#e3f2fd
    style Validate fill:#fff9c4
    style Success fill:#c8e6c9
    style Exit0 fill:#a5d6a7
    style ExitError fill:#ffcdd2
```

**Data at Key Points:**

```bash
# 1. After LoadEnv
ORG="phdsystems"
CONFIG="project-config.json"
DRY_RUN="0"

# 2. After LoadConfig
{
  "teams": ["frontend-team", "backend-team"],
  "projects": [{
    "name": "alpha",
    "repos": [{
      "name": "frontend",
      "team": "frontend-team",
      "permission": "push"
    }]
  }]
}

# 3. After ExtractTeams
teams=("frontend-team" "backend-team")

# 4. After ExtractRepos
repos=(
  {
    "project": "alpha",
    "name": "frontend",
    "full_name": "project-alpha-frontend",
    "team": "frontend-team",
    "permission": "push"
  }
)

# 5. After MatchTemplate
files=(
  {
    "repo": "project-alpha-frontend",
    "type": "README",
    "template": "templates/README-frontend.md",
    "target": "README.md"
  }
  {
    "repo": "project-alpha-frontend",
    "type": "workflow",
    "template": "templates/workflow-frontend.yml",
    "target": ".github/workflows/ci.yml"
  }
  {
    "repo": "project-alpha-frontend",
    "type": "codeowners",
    "template": "templates/CODEOWNERS",
    "target": ".github/CODEOWNERS"
  }
)

# 6. Final Output
Teams created: 2
Repositories created: 1
Files added: 3
Total API calls: 7
Execution time: 45 seconds
```

---

## 8. Data Caching and Optimization

### Current State (No Caching)

```mermaid
sequenceDiagram
    participant App
    participant API as GitHub API

    App->>API: Check team1 exists
    API-->>App: Response
    App->>API: Check team2 exists
    API-->>App: Response
    App->>API: Check repo1 exists
    API-->>App: Response
    App->>API: Check repo2 exists
    API-->>App: Response
    App->>API: Check file1 exists
    API-->>App: Response
    App->>API: Check file2 exists
    API-->>App: Response

    Note over App,API: 6 API calls<br/>No caching
```

### Potential Optimization (With Caching)

```mermaid
sequenceDiagram
    participant App
    participant Cache
    participant API as GitHub API

    App->>API: List all teams
    API-->>App: All teams data
    App->>Cache: Store teams

    App->>API: List all repos
    API-->>App: All repos data
    App->>Cache: Store repos

    App->>Cache: Check team1 exists
    Cache-->>App: Hit: Yes
    App->>Cache: Check team2 exists
    Cache-->>App: Hit: Yes
    App->>Cache: Check repo1 exists
    Cache-->>App: Hit: No
    App->>Cache: Check repo2 exists
    Cache-->>App: Hit: No

    Note over App,Cache: 2 API calls<br/>vs 6 without cache<br/>67% reduction
```

**Trade-offs:**
- **Pro:** Fewer API calls, faster execution
- **Pro:** Reduced rate limit impact
- **Con:** More complex implementation
- **Con:** Memory usage for cache
- **Con:** Potential stale data if external changes

---

*Last Updated: 2025-10-27*
