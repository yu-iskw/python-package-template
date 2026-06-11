# Loop on Thermos Review

Address review feedback until there are no issues at the target severity levels.

## Prerequisite

`/thermos` must be available (project or global `.cursor/commands/thermos.md`). If it is missing, stop and ask the user to add it.

## Target levels

Read severity levels from text the user provides after `/loop-on-thermos`.

- **Default:** `P0`, `P1` when no levels are specified.
- **Examples:** `/loop-on-thermos P0` · `/loop-on-thermos P0 P1 P2` · `/loop-on-thermos P1,P2`
- **Parsing:** Accept space- or comma-separated tokens; normalize to uppercase (`P0`–`P3` or whatever `/thermos` emits). Reject invalid tokens and ask the user to retry.
- **Priority order:** P0 → P1 → P2 → P3 (fix higher severity first).
- **Out of scope:** Issues at levels not in the target list (e.g. if targets are `P0` only, ignore P1+).

## Loop

Repeat until the latest `/thermos` review reports **zero issues at every target level**:

1. **Review** — Run `/thermos` on the current work (prefer branch diff vs base; include uncommitted changes if relevant).
2. **Triage** — Extract only issues matching the target levels. Ignore all other levels unless the user explicitly expands scope mid-run.
   - If none remain at target levels → go to **Done**.
3. **Fix one issue** — Resolve exactly **one** issue, highest severity first among target levels (P0 before P1 before P2 before P3).
4. **Commit** — Create **one git commit** for that fix. Do not batch unrelated issues.
5. **Re-review** — Return to step 1.

## Commit rules

- Commit only when an issue is fully resolved.
- Follow repo commit style (`type(scope): description` per CLAUDE.md).
- Do not push unless the user asks.
- If a pre-commit hook modifies files, fix and create a **new** commit (do not amend unless amend rules apply).

## Progress reporting

After each iteration, briefly report:

- Issue fixed (ID/title, severity)
- Commit SHA and message
- Remaining count per target level

## Done

When `/thermos` reports no issues at any target level:

- Summarize all commits made in the loop
- List any remaining issues outside target levels (informational only)
- Confirm the loop is complete
