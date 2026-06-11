---
description: Loop thermos review and fix findings until clear at a severity threshold (default P0); optional P1/P2/P3 level argument; one commit per resolved issue.
---

# Loop on Thermos

Iterate thermos review → triage → fix-and-commit → re-review until no actionable findings remain **at or above** the configured severity threshold.

This is an **in-session agent loop** (like loop-on-ci), not the `/loop` skill’s background shell ticker. Continue in the same chat until the exit condition is met.

## Usage

```text
/loop-on-thermos              → threshold P0 (default)
/loop-on-thermos P1           → threshold P1 (address P0 and P1)
/loop-on-thermos P2           → threshold P2 (address P0, P1, P2)
/loop-on-thermos P3           → threshold P0 through P3
/loop-on-thermos --level P1   → same as bare P1
```

**Threshold semantics (cumulative):** `level = Pn` means all findings with severity **P0 through Pn** are in scope for triage and fix. Findings **below** the threshold are labeled in the report but **do not block loop exit**.

| Invocation       | In-scope for fix | Blocks exit                   | Reported only |
| ---------------- | ---------------- | ----------------------------- | ------------- |
| (default) / `P0` | P0               | P0 actionable remaining       | P1, P2, P3    |
| `P1`             | P0, P1           | P0 or P1 actionable remaining | P2, P3        |
| `P2`             | P0, P1, P2       | P0–P2 actionable remaining    | P3            |
| `P3`             | P0–P3            | any actionable remaining      | —             |

Invalid values (`P4`, `high`, etc.): show usage hint; abort unless the user confirms defaulting to P0.

## Prerequisites

- **Thermos plugin** installed (`/add-plugin thermos`) so you can follow the `thermos` skill and spawn `thermo-nuclear-review-subagent` + `thermo-nuclear-code-quality-review-subagent`.
- Clean working tree or explicit user consent to commit on the current branch.
- Run `make lint && make test` before each commit (see [AGENTS.md](../../AGENTS.md)).

## Workflow

### 0. Initialize

1. **Parse severity threshold** from the invocation (default `P0`).
2. Record loop iteration count (start at 1). Echo the active threshold in the first status line.
3. Resolve review scope: `git merge-base HEAD main` (or user-provided base); collect `git diff` + changed file contents (same prep as Thermos README).
4. If no diff vs base, stop with a short message.

### 1. Review with thermos

Follow the **thermos** skill exactly:

1. Launch both subagents in parallel (`run_in_background: true`):
   - `thermo-nuclear-review-subagent` — bugs, breakages, security, devex, feature-flag leaks
   - `thermo-nuclear-code-quality-review-subagent` — maintainability, structure, spaghetti, abstractions
2. Synthesize deduplicated findings.
3. **Normalize every finding to P0–P3**:

| Level  | Thermo signals (examples)                                                                                         | Default loop (P0 threshold) | When threshold includes this level    |
| ------ | ----------------------------------------------------------------------------------------------------------------- | --------------------------- | ------------------------------------- |
| **P0** | Security vuln, data loss, breaking functionality/devex, feature-flag leak, high-confidence correctness bug        | Must fix or defer           | Must fix or defer                     |
| **P1** | High-impact contract break, code-quality approval-bar blockers (1k-line sprawl, spaghetti growth, boundary leaks) | Report only                 | Must fix or defer                     |
| **P2** | Moderate maintainability / edge-case issues                                                                       | Report only                 | Must fix or defer (if threshold ≥ P2) |
| **P3** | Low-impact nits                                                                                                   | Report only                 | Must fix or defer (if threshold = P3) |

Each finding must include: `#`, severity, `file:line`, one-line title, evidence snippet, suggested fix (if known).

Split findings into **in scope** (at or above threshold) and **below threshold** (informational).

### 2. Triage in-scope findings

Filter to findings **at or above the active threshold**. Produce a **triage table** ordered by **severity first (P0 → Pn), then high impact / low fix risk**:

- **Quick wins:** localized, mechanical, high-confidence fixes (missing guard, wrong env var name, extract helper).
- **Medium:** cross-file but still bounded refactors.
- **Hard / risky:** architectural rewrites, ambiguous intent, or **intended breakage** (per thermo-nuclear-review “Intended Breakage Guidelines”).

Present the ordered queue briefly; proceed unless the user redirects. Findings marked **intentional/accepted** or **invalid on re-check** move to “Deferred” and do not block exit once acknowledged.

**Exit check:** if zero actionable in-scope findings remain → go to step 4.

### 3. Address issues one by one (serial)

For **one** in-scope finding at a time (P0 before P1, etc.):

1. Re-read cited `file:line`; skip if evidence no longer matches (note why).
2. Implement the **smallest correct fix** for that finding only.
3. Run `make lint && make test`.
4. **Commit** one finding per commit (conventional commits):

   ```text
   fix(review): resolve thermos #N — <short title>
   ```

5. Move to the next queued in-scope finding **without** re-running thermos mid-queue.

After the queue is empty for this iteration → increment iteration count and go to step 1 (fresh thermos on updated branch).

### 4. Exit and report

When thermos reports **zero actionable findings at or above the threshold**:

- Summarize: active threshold, iterations run, commits made (SHAs + messages), deferred/skipped items, below-threshold backlog.
- Do **not** auto-push unless the user asks.

Use this output template each iteration:

```markdown
## Loop-on-thermos — iteration N (threshold: P0)

### Findings in scope

| #   | Sev | File | Title | Triage |
| --- | --- | ---- | ----- | ------ |

### Below threshold (informational)

| #   | Sev | File | Title |
| --- | --- | ---- | ----- |

### This iteration

- Fixed: #… (commit abc1234)
- Deferred: #… (reason)

### Status

- Threshold: P0
- Actionable in-scope remaining: N
- Below threshold (not blocking): N
- Next: <fix #X | re-run thermos | done>
```

## Guardrails

- One finding per commit; no drive-by refactors.
- Never use `--no-verify` or skip hooks.
- Do not “fix” in-scope findings that are intentional scope — defer with rationale instead.
- **Stuck handling:** after **5 full thermos cycles** with the same in-scope finding persisting, stop and ask the user (design decision, disputed finding, or needs human review).
- **Max scope creep:** if a fix requires touching >3 files or a design change, pause triage and ask before proceeding.
