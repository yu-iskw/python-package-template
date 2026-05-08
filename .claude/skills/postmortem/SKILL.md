---
name: postmortem
description: At the end of a coding agent session (Cursor, Claude Code, Codex, Gemini CLI, or similar), summarize outcomes, failures, inefficiencies, and root causes, then output a concise postmortem with ranked Must/Should/Consider improvements. Chat-only output; do not edit project files unless the user explicitly asks. Skip nit-picks and one-off mistakes.
compatibility: Project-level Markdown skill; loadable from standard dirs such as `.cursor/skills/` and `.claude/skills/`. Tool-agnostic; produces a Markdown report in chat with no scripts or repo changes required.
---

# Session postmortem

## Trigger scenarios

Activate when the user says or implies:

- Postmortem, retrospective, session review, end of session
- What went wrong, why we failed, lessons learned, inefficiencies, wasted tokens/time

## Non-goals

- Do **not** edit `AGENTS.md`, `CLAUDE.md`, `.cursor/rules`, `.cursor/skills`, `.claude/skills`, hooks, or subagent files unless the user **explicitly** asks for a follow-up change.
- Do **not** treat this skill as permission to refactor, fix tests, or run commands; stay analytical unless the user combines this with another task.

## Guardrails

1. **Signal only:** If a finding would not materially help a **similar** future session, omit it.
2. **Cap urgency:** At most **three** items under **Must** in "Changes for next session".
3. **Doc updates:** The section **Suggested documentation or skill updates** must be **"None warranted"** unless the issue is **recurring**, **high impact**, and plausibly preventable through focused workflow or verification guidance (e.g. repeated wrong quality gates, wrong tool assumptions, browser runtime drift that unit tests miss, systematic repo misunderstanding).

### When “recurring” counts

Treat an issue as **recurring** if **any** of the following holds:

- The **same substantive failure mode** appeared in **two or more** sessions (for example wrong quality gate, missing `uv`/Trunk on `PATH`, claiming green without `make test`).
- **One session** produced a **high-impact systematic** gap (for example every agent would miss the same verification step given current docs).

If unsure, default to **None warranted** and capture the idea under **Consider** instead.

## Instructions

1. Briefly restate the **session goal** and whether it was **met**, **partially met**, or **not met** (one short paragraph).
2. Read [`references/postmortem-report-template.md`](references/postmortem-report-template.md) if needed, then fill every section it defines with concise bullets or short paragraphs. **Output contract:** emit one Markdown document using **exactly** the `###` sections under **Report body** in that file (same wording and heading level). **Do not** include the reference’s `## Report body` line in the report.
3. End with **Changes for next session** ranked **Must / Should / Consider**.
4. If **two or more** **Must**-level items are **mutually exclusive** or **order-ambiguous**, score those options in chat using [`references/solution-scorecard.md`](references/solution-scorecard.md) (read if not already in context). Output stays in the conversation; do not edit repo files.
5. If and only if guardrail (3) applies, add **Suggested documentation or skill updates** with **proposed wording** as copy-paste snippets (still do not apply edits yourself). For each item include **Target file** (for example `AGENTS.md`, `.claude/skills/lint-and-fix/SKILL.md`), **Recurrence signal** (which bullet above matched), and **Proposed addition** (short snippet). Prefer **[AGENTS.md](../../../AGENTS.md) Agent verification gates** or the **`verifier`** subagent when the fix is repo-wide policy; prefer a specific skill when the fix is procedural only.

## Postmortem → repo promotion (when the user asks)

Chat-only postmortems do **not** edit the repo (see **Non-goals**). When the user **explicitly** asks to implement documentation or skill updates:

1. Use **Suggested documentation or skill updates** (if populated) or promote **Must**/**Should** items that match guardrail (3).
2. Apply **[AGENTS.md](../../../AGENTS.md) → Skill edit checklist** for any `SKILL.md` change.
3. Keep policy in **AGENTS.md** when possible; keep skills **how-to** and link upward.

Do **not** expand scope beyond what the user approved.

## Example (illustrative fragment)

### Example: Changes for next session

- **Must:** Run `make lint` and `make test` from the repo root before claiming complete (per AGENTS.md).
- **Should:** Read `README.md` and the touched package under `src/your_package/` before large edits.
- **Consider:** Delegate broad codebase search when the question spans many directories.

### Example: Suggested documentation or skill updates

None warranted.

### Example: When doc or skill updates are warranted

- Repeated failures from claiming “green” without `make lint` / `make test` at the repo root.
- Repeated Trunk or `uv` version drift between local runs and CI.
- Repeated late discovery of Ruff complexity (`C901`) or type issues after large refactors.
