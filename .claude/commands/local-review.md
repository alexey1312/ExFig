---
description: Run a comprehensive code review of local changes
allowed-tools: Bash(git *), Grep, Glob, Read, TodoWrite, Task(Explore), mcp__context7__resolve-library-id, mcp__context7__get-library-docs, mcp__sosumi__searchAppleDocumentation, mcp__sosumi__fetchAppleDocumentation
argument-hint: '[optional: files/directories to review]'
version: 2.0
---

# Local Development Review

Comprehensive technical code review analyzing ALL commits in feature branch relative to `origin/develop`.

## Review Scope Decision

```toon
scope[3]{condition,action}:
  "specific files/directories provided","review only those paths"
  "no arguments","review all branch changes vs origin/develop"
  "module path provided","review module + check cross-module impacts"
```

## Step 1: Fetch Latest & Identify Changes

```bash
git fetch origin

# Show all commits in feature branch
git log origin/develop..HEAD --oneline

# Show all changed files
git diff origin/develop...HEAD --name-only
```

If specific files/directories provided via arguments:

```bash
git diff origin/develop...HEAD --name-only -- [file-paths]
```

## Step 2: Read Review Guidelines

Read recipe files before flagging issues:

```toon
recipes[6]{category,path}:
  "SwiftUI crashes","docs/agents/development/recipes/code-review/swiftui-crash-recipes.md"
  "Memory management","docs/agents/development/recipes/code-review/memory-management-recipes.md"
  "Security","docs/agents/development/recipes/code-review/security-recipes.md"
  "Swift 6 concurrency","docs/agents/development/recipes/code-review/swift6-concurrency-recipes.md"
  "Architecture violations","docs/agents/development/recipes/code-review/architecture-violation-recipes.md"
  "Output format","docs/agents/development/recipes/code-review/code-review-output-recipes.md"
```

## Step 3: Perform Review

Follow @docs/agents/development/code-review.md methodology:

```toon
methodology[5]{step,action}:
  1,"Extract context: iOS version, UI framework, architectural layer"
  2,"Pattern match: verify ALL conditions from detection rules"
  3,"Assess confidence: >=80% flag, <80% skip"
  4,"Verify against recipes: read linked recipe files before flagging"
  5,"Prioritize: CRITICAL -> HIGH -> MEDIUM"
```

## Step 4: Generate Output

Output format per @docs/agents/development/recipes/code-review/code-review-output-recipes.md:

```toon
output[3]{section,format,required}:
  "Code Review Complete","[one line summary]",true
  "Review Findings","[grouped by priority]",true
  "No issues","No critical, high, or medium priority issues detected",conditional
```

Priority format: `emoji + description + file:line + fix action`

```toon
priorities[3]{level,emoji,examples}:
  CRITICAL,"red circle","crashes, security, memory leaks"
  HIGH,"yellow circle","architecture violations, missing error handling"
  MEDIUM,"green circle","performance, code quality"
```

## Quality Gate

```toon
checklist[5]{check,required}:
  "All changed files reviewed",true
  "Recipe files consulted for detected issues",true
  "Confidence >= 80% for all flagged issues",true
  "Output follows code-review-output-recipes.md format",true
  "No false positives from partial pattern matches",true
```
