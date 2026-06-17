---
description: Loop thermos review and fix findings until clear at configurable severity levels (default P0, P1); one commit per resolved issue.
---

# Loop on Thermos

Address review feedback until there are no issues at the target severity levels.

This is an **in-session agent loop** (like loop-on-ci), not the `/loop` skill's background shell ticker. Continue in the same chat until the exit condition is met.

## Target levels

Read severity levels from text the user provides after `/loop-on-thermos`.

- **Default:** `P0`, `P1` when no levels are specified.
- **Examples:** `/loop-on-thermos P0` · `/loop-on-thermos P0 P1 P2` · `/loop-on-thermos P1,P2`
- **Parsing:** Accept space- or comma-separated tokens; normalize to uppercase (`P0`–`P3` or whatever `/thermos` emits). Reject invalid tokens and ask the user to retry.
- **Priority order:** P0 → P1 → P2 → P3 (fix higher severity first).
- **Out of scope:** Issues at levels not in the target list (e.g. if targets are `P0` only, ignore P1+).

| Invocation                  | Target levels        |
| --------------------------- | -------------------- |
| `/loop-on-thermos`          | `P0`, `P1` (default) |
| `/loop-on-thermos P0`       | `P0` only            |
| `/loop-on-thermos P0 P1 P2` | `P0`, `P1`, `P2`     |
| `/loop-on-thermos P1,P2`    | `P1`, `P2`           |

## Prerequisites

- **Thermos plugin** installed (`/add-plugin thermos`) so you can follow the `thermos` skill and spawn `thermo-nuclear-review-subagent` + `thermo-nuclear-code-quality-review-subagent`.
- Clean working tree or explicit user consent to commit on the current branch.
- Run `make lint && make test` before each commit (see [AGENTS.md](../../AGENTS.md)).

## Loop

Repeat until the latest thermos review reports **zero issues at every target level**:

### 0. Initialize

1. **Parse target levels** from the invocation (default `P0`, `P1`).
2. Record loop iteration count (start at 1). Echo the active target levels in the first status line.
3. Resolve review scope: `git merge-base HEAD main` (or user-provided base); collect `git diff` + changed file contents (same prep as Thermos README).
4. If no diff vs base, stop with a short message.

### 1. Review with thermos

Follow the **thermos** skill exactly:

1. Launch both subagents in parallel (`run_in_background: true`):
   - `thermo-nuclear-review-subagent` — bugs, breakages, security, devex, feature-flag leaks
   - `thermo-nuclear-code-quality-review-subagent` — maintainability, structure, spaghetti, abstractions
2. Synthesize deduplicated findings.
3. **Normalize every finding to P0–P3**:

| Level  | Thermo signals (examples)                                                                                         |
| ------ | ----------------------------------------------------------------------------------------------------------------- |
| **P0** | Security vuln, data loss, breaking functionality/devex, feature-flag leak, high-confidence correctness bug        |
| **P1** | High-impact contract break, code-quality approval-bar blockers (1k-line sprawl, spaghetti growth, boundary leaks) |
| **P2** | Moderate maintainability / edge-case issues                                                                       |
| **P3** | Low-impact nits                                                                                                   |

Each finding must include: `#`, severity, `file:line`, one-line title, evidence snippet, suggested fix (if known).

### 2. Triage

Extract only issues matching the **target levels**. Ignore all other levels unless the user explicitly expands scope mid-run.

Produce a **triage table** ordered by **severity first (P0 → P3 among targets), then high impact / low fix risk**:

- **Quick wins:** localized, mechanical, high-confidence fixes.
- **Medium:** cross-file but still bounded refactors.
- **Hard / risky:** architectural rewrites, ambiguous intent, or **intended breakage** (per thermo-nuclear-review "Intended Breakage Guidelines").

Present the ordered queue briefly; proceed unless the user redirects. Findings marked **intentional/accepted** or **invalid on re-check** move to "Deferred" and do not block exit once acknowledged.

- If none remain at target levels → go to **Done**.

### 3. Fix one issue

For **one** target-level finding at a time (highest severity first among target levels: P0 before P1 before P2 before P3):

1. Re-read cited `file:line`; skip if evidence no longer matches (note why).
2. Implement the **smallest correct fix** for that finding only.
3. Run `make lint && make test`.
4. **Commit** — create **one git commit** for that fix. Do not batch unrelated issues:

   ```text
   fix(review): resolve thermos #N — <short title>
   ```

5. Move to the next queued target-level finding **without** re-running thermos mid-queue.

After the queue is empty for this iteration → increment iteration count and return to step 1 (fresh thermos on updated branch).

## Commit rules

- Commit only when an issue is fully resolved.
- Follow repo commit style (`type(scope): description` per CLAUDE.md).
- Do not push unless the user asks.
- Never use `--no-verify` or skip hooks.
- If a pre-commit hook modifies files, fix and create a **new** commit (do not amend unless amend rules apply).

## Progress reporting

After each iteration, briefly report:

- Issue fixed (ID/title, severity)
- Commit SHA and message
- Remaining count per target level

Use this output template each iteration:

```markdown
## Loop-on-thermos — iteration N (targets: P0, P1)

### Findings in scope

| #   | Sev | File | Title | Triage |
| --- | --- | ---- | ----- | ------ |

### Outside target levels (informational)

| #   | Sev | File | Title |
| --- | --- | ---- | ----- |

### This iteration

- Fixed: #… (commit abc1234)
- Deferred: #… (reason)

### Status

- Target levels: P0, P1
- Remaining per level: P0=N, P1=N, …
- Outside targets (not blocking): N
- Next: <fix #X | re-run thermos | done>
```

## Done

When thermos reports no issues at any target level:

- Summarize all commits made in the loop
- List any remaining issues outside target levels (informational only)
- Confirm the loop is complete
- Do **not** auto-push unless the user asks.

## Guardrails

- One finding per commit; no drive-by refactors.
- Do not "fix" target-level findings that are intentional scope — defer with rationale instead.
- **Stuck handling:** after **5 full thermos cycles** with the same target-level finding persisting, stop and ask the user.
- **Max scope creep:** if a fix requires touching >3 files or a design change, pause triage and ask before proceeding.
