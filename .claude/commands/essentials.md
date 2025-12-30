---
argument-hint: <github-pr-url>
description: Analyze Essential Feed tests and create implementation plan adapted for NASA Gallery async/await architecture
allowed-tools: WebFetch(domain:github.com), Read, Glob, Grep, Bash(git:*)
---

# Essentials Feed Test Analyzer

## Mission

Analyze tests from an Essential Feed case study PR and create a comprehensive implementation plan for the NASA Gallery project, adapting callback-based patterns to async/await architecture.

## Input

GitHub PR/diff URL from Essential Feed case study, like:
- `https://github.com/essentialdevelopercom/essential-feed-case-study/pull/20/files`

## Workflow

### Phase 1: Analysis & Extraction

1. **Fetch the GitHub diff** - Get all file changes from the PR
2. **Extract all tests** - Identify every test case and its purpose
3. **Understand corner cases** - Analyze edge cases, error scenarios, and happy paths
4. **Identify patterns** - Protocol designs, test doubles, composition patterns

### Phase 2: Architecture Mapping

Map Essential Feed patterns to NASA Gallery equivalents:

| Essential Feed | NASA Gallery |
|----------------|--------------|
| Completion handlers | async/await |
| Callback-based APIs | Async functions |
| Expectation helpers | Continuations |
| Dispatch queue testing | Structured concurrency |

### Phase 3: Create Implementation Plan

Generate a structured plan with:

#### 1. Executive Summary
- What functionality is being tested
- Key architectural patterns involved
- Number of tests to implement
- Already-implemented tests (check NASA Gallery codebase)

#### 2. Test Extraction Checklist

For each test, create an entry:
```
- [ ] Test: <test_name>
  Purpose: <what it verifies>
  Pattern: <design pattern used>
  Corner case: <edge case or scenario>
  Status: [NEW | ALREADY IMPLEMENTED]
```

#### 3. Implementation Plan (Per Test)

For each NEW test needed:

```markdown
## Test #N: <TestClassName>.<testMethodName>

### Purpose
<What behavior/requirement this test verifies>

### Original Essential Feed Code
<Show relevant snippets from the PR diff>

### NASA Gallery Test Code (Adapted)
<Test code adapted for async/await, UICollectionView, etc.>

### Production Code Needed
<Minimal implementation to make test pass>

### Key Differences from Essential Feed
- Async/await instead of completion handlers
- Task cancellation handling
- Continuation-based spy patterns
- UICollectionView vs UITableView specifics

### Implementation Notes
<Any gotchas, considerations, or Swift Concurrency specifics>
```

#### 4. Condensed Insights for tips.md

Extract key learnings like:
- Design patterns discovered (e.g., Spy pattern, protocol composition)
- Why this approach is good practice
- Testing techniques learned
- Async/await adaptations made
- Common pitfalls avoided

Format as brief, actionable bullet points suitable for tips.md.

### Phase 4: Check Existing Implementation

Before planning each test:
1. Search NASA Gallery codebase for similar test names
2. Check if functionality is already tested
3. Mark tests as [ALREADY IMPLEMENTED] if found
4. Only plan NEW tests that don't exist yet

## Output Format

```markdown
# Essential Feed PR Analysis: <PR Title>

## Executive Summary
- PR URL: <url>
- Functionality: <what's being tested>
- Total tests in PR: X
- Already implemented in NASA Gallery: Y
- New tests needed: Z

## Test Extraction

### All Tests from PR
<Checklist with status markers>

## Implementation Plan

### Tests Already Implemented ✅
<List tests found in NASA Gallery>

### New Tests Needed 📝
<Per-test breakdown with test + production code>

## Key Insights for tips.md

<Condensed bullet points>
- Pattern: <pattern> - <why it's good>
- Technique: <technique> - <benefit>
- Gotcha: <pitfall> - <how to avoid>
```

## Important Notes

- **Plan first, execute later** - Create the plan for user review before implementing
- **Both test + production together** - Show both code blocks for each test
- **Check for duplicates** - Search NASA Gallery before planning new tests
- **Adapt, don't copy** - Translate callback patterns to async/await
- **Account for differences** - UICollectionView vs UITableView, Task cancellation, etc.
- **Be thorough** - Extract EVERY test, even trivial ones
- **Be concise in tips.md** - Only the most valuable insights

## Success Criteria

1. Every test from the Essential Feed PR is extracted
2. Already-implemented tests are identified
3. New tests have both test + production code outlined
4. Async/await adaptations are clearly explained
5. Insights are condensed and actionable for tips.md
6. User can review and approve before implementation begins
