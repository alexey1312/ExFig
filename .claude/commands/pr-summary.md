---
description: Generate PR summary from branch changes for GitHub
allowed-tools: Bash(git *), Bash(pbcopy), Read, Glob, Grep, Write
version: 2.0
---

# PR Summary Generator

Generate a concise PR summary in English based on branch changes, copy to clipboard.

## Step 1: Gather Context

```bash
git branch --show-current
git fetch origin
git log origin/develop..HEAD --oneline
git diff origin/develop...HEAD --stat
```

## Step 2: Extract Task ID

Extract from branch name using pattern `[A-Z]+-[0-9]+`:

```toon
patterns[4]{branch_example,extracted_id}:
  "feature/PL-19452-description","PL-19452"
  "fix/COUR-8147-bug","COUR-8147"
  "hotfix/PAX-123-critical","PAX-123"
  "feature/some-description","[manual input required]"
```

## Step 3: Generate Summary

Write to `/tmp/pr-summary.md`:

```toon
template{section,format}:
  Title: "imperative mood, max 50 chars (Add/Fix/Update/Remove)"
  Task ID: "[{ID}](https://indriver.atlassian.net/browse/{ID})"
  Description: "1-2 sentences: what changed and why"
  Changes: "- bullet list of changes"
```

Template:

```markdown
## Title
<imperative mood, max 50 chars>

## Task ID
[{TASK_ID}](https://indriver.atlassian.net/browse/{TASK_ID})

## Description
<1-2 sentences>

- <change 1>
- <change 2>
```

## Step 4: Copy to Clipboard

```bash
cat /tmp/pr-summary.md | pbcopy
```

Inform user: "Copied to clipboard!"

## Output Format

```toon
sections[4]{name,format,required}:
  Title,"imperative mood max 50 chars",true
  "Task ID","markdown link to Jira",true
  Description,"1-2 sentences explaining what/why",true
  Changes,"bullet list of specific changes",true
```

## Quality Gate

```toon
checklist[5]{check,required}:
  "Title in imperative mood (not past tense)",true
  "Task ID extracted and formatted as link",true
  "English only, formal tone",true
  "Summary written to /tmp/pr-summary.md",true
  "Result copied to clipboard via pbcopy",true
```
