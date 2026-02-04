---
name: parallel-executor
description: Execute complex tasks using parallel subagents. Use for large tasks that benefit from concurrent execution. Automatically plans, decomposes, and orchestrates parallel work.
---

# Parallel Task Executor

## Purpose

This skill orchestrates the execution of complex tasks by:
1. Using the `parallel-tasks-planner` agent to decompose the task
2. Executing independent subtasks in parallel using background agents
3. Coordinating sequential phases based on dependencies
4. Aggregating results and reporting completion

## Arguments

- `$ARGUMENTS`: Description of the complex task to execute

## Workflow

### Phase 1: Planning

First, invoke the `parallel-tasks-planner` agent to create an execution plan.

Use the Task tool with subagent_type "Plan" or invoke the parallel-tasks-planner agent directly with the task description.

The planner will output a YAML task execution plan with:
- Phases of execution
- Tasks within each phase
- File ownership for each task
- Dependencies between phases

### Phase 2: Validate Plan

Before execution, validate the plan:

1. **Check for file conflicts**: No file should appear in multiple parallel tasks
2. **Verify dependencies**: All `depends_on` references exist
3. **Confirm completeness**: All aspects of original task are covered

### Phase 3: Execute Phases

Execute each phase in order:

#### For Parallel Phases

Launch all tasks in the phase simultaneously by making multiple Task tool calls in a SINGLE message. This is critical for true parallelism.

**IMPORTANT**: To run tasks in parallel, you MUST include multiple Task tool invocations in the same response message. Each task should use `run_in_background: true`.

Example pattern for 3 parallel tasks:

```
In a single assistant response, call Task tool 3 times:

Task call 1:
  - description: "Task 1a: Create user model"
  - prompt: [detailed instructions]
  - subagent_type: "general-purpose"
  - run_in_background: true

Task call 2:
  - description: "Task 1b: Create JWT utilities"
  - prompt: [detailed instructions]
  - subagent_type: "general-purpose"
  - run_in_background: true

Task call 3:
  - description: "Task 1c: Create auth config"
  - prompt: [detailed instructions]
  - subagent_type: "general-purpose"
  - run_in_background: true
```

Each background task returns an `output_file` path. Store these paths.

#### Monitor Background Tasks

After launching parallel tasks, you'll be notified when they complete. You can also check progress:

```bash
# Check if task is still running
tail -20 /tmp/claude/.../tasks/{agent_id}.output

# Read full output when done
cat /tmp/claude/.../tasks/{agent_id}.output
```

#### Wait for Phase Completion

Before starting the next phase:
1. Ensure all background tasks from current phase are complete
2. Check each task's output for success/failure
3. Aggregate any results needed for next phase

#### For Sequential Phases

Execute tasks one at a time, waiting for completion before the next:

```
Task call (foreground):
  - description: "Task 2: Integration"
  - prompt: [detailed instructions]
  - subagent_type: "general-purpose"
  - run_in_background: false (or omit)
```

### Phase 4: Verification

After all phases complete:

1. **Run verification**: Invoke the `verifier` agent to run build/lint/test
2. **Check for conflicts**: Ensure no merge conflicts from parallel work
3. **Validate integration**: Confirm all pieces work together

```bash
# Quick verification
make lint && make test
```

### Phase 5: Report Results

Summarize execution:

```
## Parallel Execution Summary

### Task: {original task description}

### Execution Phases
- Phase 1: {N} tasks completed in parallel
- Phase 2: {M} tasks completed sequentially
- Phase 3: {P} tasks completed in parallel

### Results
- Total tasks: {total}
- Successful: {success_count}
- Failed: {failure_count}

### Files Modified
- {list of all files modified}

### Verification
- Build: PASS/FAIL
- Lint: PASS/FAIL
- Tests: PASS/FAIL
```

## Example Execution

**Input**: `/parallel-executor Add comprehensive logging to the application`

**Execution**:

1. **Plan** (parallel-tasks-planner agent):
   ```yaml
   phases:
     - phase: 1
       parallel: true
       tasks:
         - id: "logging-config"
           files: ["src/config/logging.py"]
         - id: "logging-utils"
           files: ["src/utils/logger.py"]
     - phase: 2
       parallel: true
       tasks:
         - id: "api-logging"
           files: ["src/api/*.py"]
         - id: "db-logging"
           files: ["src/db/*.py"]
     - phase: 3
       parallel: true
       tasks:
         - id: "logging-tests"
           files: ["tests/test_logging.py"]
         - id: "logging-docs"
           files: ["docs/logging.md"]
   ```

2. **Execute Phase 1** (parallel):
   - Launch "logging-config" agent in background
   - Launch "logging-utils" agent in background
   - Wait for both to complete

3. **Execute Phase 2** (parallel):
   - Launch "api-logging" agent in background
   - Launch "db-logging" agent in background
   - Wait for both to complete

4. **Execute Phase 3** (parallel):
   - Launch "logging-tests" agent in background
   - Launch "logging-docs" agent in background
   - Wait for both to complete

5. **Verify**: Run `make lint && make test`

6. **Report**: Summarize 6 tasks across 3 phases

## Best Practices

1. **Maximize parallelism**: Put independent tasks in the same phase
2. **Minimize phases**: Fewer phases = faster completion
3. **Clear file boundaries**: Each file owned by exactly one task
4. **Detailed prompts**: Give subagents enough context to work independently
5. **Verify early**: Run quick checks between phases if possible

## Troubleshooting

### Task Conflicts
If parallel tasks modify the same file:
- Stop execution
- Re-plan with proper file isolation
- Or make conflicting tasks sequential

### Task Failure
If a background task fails:
- Read its output file for error details
- Fix the issue
- Re-run only the failed task (use agent resume if possible)

### Integration Issues
If verified tests fail after all phases:
- Check for missing imports between modules
- Verify interfaces match between parallel implementations
- Run integration manually to debug
