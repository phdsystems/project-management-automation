# CI Parallelization Strategies

**Date:** 2025-10-27

## Overview

Comparison of different parallelization strategies for running tests in GitHub Actions.

---

## Strategy 1: Test-Type Level Parallelization (Current)

**File:** `.github/workflows/test.yml`

### Configuration

```yaml
jobs:
  test:
    strategy:
      matrix:
        test-type: [unit, integration, e2e]
```

### Execution Model

```
Workflow Start
    |
    +------------------+------------------+
    |                  |                  |
    v                  v                  v
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Runner 1  │  │   Runner 2  │  │   Runner 3  │
├─────────────┤  ├─────────────┤  ├─────────────┤
│ Unit Tests  │  │ Integration │  │  E2E Tests  │
│             │  │    Tests    │  │             │
│ - auth      │  │ - prereqs   │  │ - workflow  │
│ - api-teams │  │ - dry-run   │  │ - errors    │
│ - api-users │  │ - teams     │  │             │
│ - repo      │  │ - repos     │  │             │
│ - jq        │  │             │  │             │
│             │  │             │  │             │
│ Sequential  │  │ Sequential  │  │ Sequential  │
└─────────────┘  └─────────────┘  └─────────────┘
     ~25s             ~35s             ~40s
```

### Performance

| Metric | Value |
|--------|-------|
| **Total Jobs** | 3 parallel |
| **Runners Used** | 3 |
| **Wall-Clock Time** | ~40s (longest job) |
| **CPU Time** | ~100s (sum of all jobs) |
| **Speedup** | 2.5x vs sequential |

### Pros

✅ **Simple configuration** - One matrix dimension
✅ **Easy to understand** - Clear job grouping
✅ **Good speedup** - 2.5x faster than sequential
✅ **Logical grouping** - Tests grouped by type
✅ **Efficient for small suites** - Minimal overhead
✅ **Easy debugging** - Clear job boundaries

### Cons

❌ **Limited parallelization** - Only 3 parallel jobs
❌ **Unbalanced** - Jobs take different times (25s vs 40s)
❌ **Bottleneck** - Slowest job determines total time
❌ **Resource underutilization** - Fast jobs finish early

### Best For

- Small to medium test suites (< 20 tests)
- When tests are naturally grouped
- When you want simple, maintainable CI
- When GitHub Actions minutes are limited

---

## Strategy 2: Test-File Level Parallelization (Maximum)

**File:** `.github/workflows/test-parallel.yml`

### Configuration

```yaml
jobs:
  test-unit:
    strategy:
      matrix:
        test-file: [test-gh-auth, test-gh-api-teams, ...]

  test-integration:
    strategy:
      matrix:
        test-file: [test-makefile-prereqs, ...]

  test-e2e:
    strategy:
      matrix:
        test-file: [test-full-workflow, ...]
```

### Execution Model

```
Workflow Start
    |
    +------+------+------+------+------+------+------+------+------+------+------+
    |      |      |      |      |      |      |      |      |      |      |      |
    v      v      v      v      v      v      v      v      v      v      v      v
  ┌───┐  ┌───┐  ┌───┐  ┌───┐  ┌───┐  ┌───┐  ┌───┐  ┌───┐  ┌───┐  ┌───┐  ┌───┐
  │ 1 │  │ 2 │  │ 3 │  │ 4 │  │ 5 │  │ 6 │  │ 7 │  │ 8 │  │ 9 │  │10 │  │11 │
  └───┘  └───┘  └───┘  └───┘  └───┘  └───┘  └───┘  └───┘  └───┘  └───┘  └───┘
  auth   teams  users  repo   jq     pre    dry    team   repo   flow   err
  ~5s    ~5s    ~5s    ~5s    ~5s    ~10s   ~8s    ~9s    ~8s    ~25s   ~15s

Maximum wall-clock time: ~25s (longest individual test)
```

### Performance

| Metric | Value |
|--------|-------|
| **Total Jobs** | 11 parallel |
| **Runners Used** | 11 |
| **Wall-Clock Time** | ~25s (longest test) |
| **CPU Time** | ~100s (same as strategy 1) |
| **Speedup** | 4x vs sequential |

### Pros

✅ **Maximum parallelization** - 11 parallel jobs
✅ **Balanced load** - Similar execution times
✅ **Fast feedback** - 25s total (vs 40s)
✅ **Fine-grained retries** - Rerun individual tests
✅ **Better resource utilization** - All runners busy
✅ **Isolated failures** - Easier to identify failures

### Cons

❌ **Complex configuration** - Multiple matrix dimensions
❌ **More runners** - Higher GitHub Actions cost
❌ **Setup overhead** - 11x checkout, 11x setup
❌ **More API calls** - Can hit rate limits
❌ **Harder to debug** - Many parallel logs
❌ **Overkill for small suites** - Diminishing returns

### Best For

- Large test suites (> 50 tests)
- When fast feedback is critical
- When you have unlimited GitHub Actions minutes
- When tests are completely independent
- When debugging individual test failures

---

## Strategy 3: Hybrid Approach

**Combine both strategies for optimal balance**

### Configuration

```yaml
jobs:
  # Quick feedback: Run fast unit tests in parallel
  test-unit-parallel:
    strategy:
      matrix:
        test-file: [test-gh-auth, test-gh-api-teams, ...]

  # Grouped: Run integration/e2e as groups
  test-integration:
    runs-on: ubuntu-latest
    steps:
      - run: ./tests/run-tests.sh integration

  test-e2e:
    runs-on: ubuntu-latest
    steps:
      - run: ./tests/run-tests.sh e2e
```

### Execution Model

```
Unit Tests (Parallel)          Integration/E2E (Grouped)
    |                                   |
    v                                   v
┌────────┬────────┬────────┐     ┌──────────┬──────────┐
│ auth   │ teams  │ users  │     │ integ.   │   e2e    │
│  ~5s   │  ~5s   │  ~5s   │     │  ~35s    │   ~40s   │
└────────┴────────┴────────┘     └──────────┴──────────┘
    Fast feedback (~5s)          Slower but logical (~40s)
```

### Performance

| Metric | Value |
|--------|-------|
| **Total Jobs** | 7 parallel |
| **Wall-Clock Time** | ~40s |
| **Speedup** | 2.5x vs sequential |
| **Balance** | Good cost/performance |

### Pros

✅ **Fast unit test feedback** - 5s for quick validation
✅ **Reasonable runner usage** - 7 runners
✅ **Logical grouping** - Complex tests grouped
✅ **Balanced complexity** - Not too simple, not too complex

### Best For

- Most projects
- When you want fast feedback for unit tests
- When integration/e2e tests are complex
- Good balance of speed and cost

---

## Comparison Table

| Strategy | Jobs | Runners | Time | Speedup | Complexity | Cost | Best For |
|----------|------|---------|------|---------|------------|------|----------|
| **Test-Type** | 3 | 3 | 40s | 2.5x | Low | Low | Small suites |
| **Test-File** | 11 | 11 | 25s | 4x | High | High | Large suites |
| **Hybrid** | 7 | 7 | 40s | 2.5x | Medium | Medium | Most projects |

---

## GitHub Actions Matrix Syntax

### Basic Matrix

```yaml
strategy:
  matrix:
    test-type: [unit, integration, e2e]
```

**Expands to 3 jobs:**
- `test-type: unit`
- `test-type: integration`
- `test-type: e2e`

### Multi-Dimensional Matrix

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest]
    test-type: [unit, integration]
```

**Expands to 4 jobs:**
- `os: ubuntu-latest, test-type: unit`
- `os: ubuntu-latest, test-type: integration`
- `os: macos-latest, test-type: unit`
- `os: macos-latest, test-type: integration`

### Matrix with Exclusions

```yaml
strategy:
  matrix:
    test-type: [unit, integration, e2e]
    exclude:
      - test-type: e2e  # Don't run e2e in matrix
```

### Matrix with Includes

```yaml
strategy:
  matrix:
    test-type: [unit, integration]
    include:
      - test-type: e2e
        timeout: 60  # e2e gets extra timeout
```

### Dynamic Matrix from JSON

```yaml
jobs:
  generate-matrix:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    steps:
      - id: set-matrix
        run: |
          TESTS=$(find tests/unit -name "test-*.sh" -exec basename {} .sh \; | jq -R -s -c 'split("\n")[:-1]')
          echo "matrix={\"test\":$TESTS}" >> $GITHUB_OUTPUT

  test:
    needs: generate-matrix
    strategy:
      matrix: ${{ fromJson(needs.generate-matrix.outputs.matrix) }}
```

---

## Accessing Matrix Values

### In Workflow YAML

```yaml
- name: Run ${{ matrix.test-type }} tests
  run: ./tests/run-tests.sh ${{ matrix.test-type }}
```

### In Job Names

```yaml
jobs:
  test:
    name: Test (${{ matrix.test-type }})
    strategy:
      matrix:
        test-type: [unit, integration, e2e]
```

**Shows as:**
- "Test (unit)"
- "Test (integration)"
- "Test (e2e)"

### In Artifact Names

```yaml
- uses: actions/upload-artifact@v3
  with:
    name: logs-${{ matrix.test-type }}-${{ matrix.os }}
    path: /tmp/logs/
```

---

## GitHub Actions Limits

| Limit | Free | Pro | Enterprise |
|-------|------|-----|------------|
| **Max parallel jobs** | 20 | 40 | 180 |
| **Minutes/month** | 2,000 | 3,000 | 50,000 |
| **Storage** | 500 MB | 2 GB | 50 GB |
| **Artifact retention** | 90 days | 90 days | 400 days |

**Cost Considerations:**
- Linux runners: 1x multiplier
- Windows runners: 2x multiplier
- macOS runners: 10x multiplier

**Example:**
- 11 parallel jobs × 25s = 11 × 0.42 minutes = 4.6 minutes
- vs 3 parallel jobs × 40s = 3 × 0.67 minutes = 2 minutes

Maximum parallelization uses ~2.3x more minutes.

---

## Recommendations

### Small Projects (< 20 tests)
**Use Strategy 1 (Test-Type)**
- 3 parallel jobs
- Simple configuration
- Low cost
- Good speedup

### Medium Projects (20-50 tests)
**Use Strategy 3 (Hybrid)**
- Parallelize unit tests
- Group integration/e2e
- Balanced approach
- Fast feedback where it matters

### Large Projects (> 50 tests)
**Use Strategy 2 (Test-File)**
- Maximum parallelization
- Fast feedback
- Worth the complexity
- Better developer experience

---

## Current Implementation

**This project uses Strategy 1 (Test-Type Level)**

**Rationale:**
- ✅ 11 total tests (small suite)
- ✅ Simple, maintainable configuration
- ✅ Good speedup (2.5x)
- ✅ Low GitHub Actions cost
- ✅ Logical test grouping
- ✅ Easy to debug

**To switch to Strategy 2:**
```bash
# Rename current workflow
mv .github/workflows/test.yml .github/workflows/test-grouped.yml

# Activate parallel workflow
mv .github/workflows/test-parallel.yml .github/workflows/test.yml

# Commit
git add .github/workflows/
git commit -m "ci: switch to maximum parallelization"
git push
```

---

## Monitoring Performance

### View Job Duration

```bash
# Using GitHub CLI
gh run list --workflow=test.yml --limit 10
gh run view <run-id> --log
```

### Analyze Bottlenecks

```yaml
- name: Start timing
  run: echo "START_TIME=$(date +%s)" >> $GITHUB_ENV

- name: Run tests
  run: ./tests/run-tests.sh unit

- name: End timing
  run: |
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    echo "Test duration: ${DURATION}s"
```

### GitHub Actions Insights

View at: `https://github.com/{org}/{repo}/actions/workflows/{workflow}.yml`

Shows:
- Job duration trends
- Success/failure rates
- Runner performance
- Bottleneck identification

---

**Summary:** Current implementation uses test-type parallelization (Strategy 1) which provides an excellent balance of simplicity, speed, and cost for this project's 11-test suite.

*Last Updated: 2025-10-27*
