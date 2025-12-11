---
description: Break down a task into subtasks with dependencies for parallel execution
allowed-tools: Read, Glob, Grep, TodoWrite, Task(Explore), Task(Plan)
argument-hint: <task description>
version: 1.0
---

# Task Planning with Dependencies

**Purpose**: Analyze a task and break it down into subtasks with explicit dependencies, enabling parallel execution
where possible.

## Output Format (TOON-like)

Generate plan in this structured format:

```yaml
command:
  name: plan-<task-slug>
  purpose: <task description>
  version: 1.0

tasks[N]{id,title,description,depends_on,parallel_group,type}:
  <id>,<title>,<description>,[deps],[group],[type]
  ...

execution_order:
  phase_1:
    parallel: [task_ids that can run in parallel]
  phase_2:
    sequential: [task_id] # build/test tasks
  phase_3:
    parallel: [task_ids for fixes if needed]
  ...

dependency_graph:
  <task_id>: [list of task_ids this depends on]
  ...
```

## Task Types

- `analysis` - Code analysis, research, reading
- `implementation` - Writing new code
- `modification` - Changing existing code
- `build` - Building project/module
- `test` - Running tests
- `fix` - Fixing issues found by build/tests
- `review` - Code review, validation

## Dependency Rules

### Critical Rules for Parallel Execution

1. **Independent tasks** (no shared files/modules) can run in parallel
2. **Build tasks** MUST wait for ALL parallel implementation tasks to complete
3. **Test tasks** MUST wait for build to succeed
4. **Fix tasks** MUST wait for test results
5. **Tasks modifying same file** MUST be sequential

### Dependency Detection

- Same file modification → sequential
- Same module modification → sequential (unless different files)
- Different modules → parallel possible
- Build depends on → all implementation tasks
- Test depends on → successful build
- Fix depends on → test results

## Instructions

1. **Analyze the task**:

   - Read relevant code files mentioned in task
   - Identify affected modules/files
   - Detect potential conflicts

2. **Break down into subtasks**:

   - Create atomic, independent subtasks where possible
   - Identify dependencies between subtasks
   - Group parallelizable tasks

3. **Generate execution plan**:

   - Phase 1: Parallel analysis/implementation tasks
   - Phase 2: Build (waits for Phase 1)
   - Phase 3: Tests (waits for Phase 2)
   - Phase 4: Fixes if needed (based on Phase 3 results)
   - Phase 5: Final build/test validation

4. **Output the plan** in TOON format above

## Example Output

```yaml
command:
  name: plan-add-analytics-tracking
  purpose: Add analytics tracking to user profile module
  version: 1.0

tasks[6]{id,title,description,depends_on,parallel_group,type}:
  T1,Create analytics service,Implement AnalyticsService protocol,[],G1,implementation
  T2,Add tracking to ProfileView,Integrate analytics calls,[],G1,implementation
  T3,Add tracking to SettingsView,Integrate analytics calls,[],G1,implementation
  T4,Build module,Build UserProfile module,[T1,T2,T3],G2,build
  T5,Run tests,Execute unit tests,[T4],G3,test
  T6,Fix issues,Address any test failures,[T5],G4,fix

execution_order:
  phase_1:
    parallel: [T1, T2, T3]  # Can run simultaneously - different files
  phase_2:
    sequential: [T4]  # Build waits for all implementations
  phase_3:
    sequential: [T5]  # Tests wait for build
  phase_4:
    conditional: [T6]  # Only if tests fail

dependency_graph:
  T1: []
  T2: []
  T3: []
  T4: [T1, T2, T3]
  T5: [T4]
  T6: [T5]

notes:
  - T1, T2, T3 modify different files, safe to parallelize
  - T4 must wait for ALL implementations before building
  - T6 is conditional - only execute if T5 finds failures
```

## Validation Checklist

Before finalizing plan, verify:

- [ ] No circular dependencies
- [ ] Build tasks depend on ALL related implementations
- [ ] Test tasks depend on successful build
- [ ] Fix tasks depend on test results
- [ ] Parallel tasks don't modify same files
- [ ] All task IDs are unique
- [ ] dependency_graph matches depends_on fields
