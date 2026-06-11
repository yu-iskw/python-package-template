# Loop on Thermos Review

Address review feedback until there are no P0 and P1 issues.

## Prerequisite

`/thermos` must be available (project or global `.cursor/commands/thermos.md`). If it is missing, stop and ask the user to add it.

## Loop

Repeat until the latest `/thermos` review reports **zero P0 and zero P1** issues:

1. **Review** — Run `/thermos` on the current work (prefer branch diff vs base; include uncommitted changes if relevant).
2. **Triage** — Extract all P0 and P1 issues from the review. Ignore P2+ unless the user says otherwise.
   - If none remain → go to **Done**.
3. **Fix one issue** — Resolve exactly **one** issue, highest severity first (all P0 before any P1).
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
- Remaining P0/P1 count

## Done

When `/thermos` reports no P0 or P1 issues:

- Summarize all commits made in the loop
- List any remaining P2+ items (informational only)
- Confirm the loop is complete
