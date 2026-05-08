---
name: lint-and-fix
description: Run linters and fix violations, formatting errors, or style mismatches using Trunk, plus dead-code detection with Vulture. Use when code quality checks fail, before submitting PRs, or to repair broken linting states.
---

# Lint and Fix Loop: Trunk

## Purpose

An autonomous loop for the agent to identify, fix, and verify linting and formatting violations using [Trunk](https://trunk.io), plus dead-code detection with [Vulture](https://github.com/jendrikseipp/vulture).

Repo-wide success criteria and **`uv`/PATH expectations** are summarized in **[AGENTS.md](../../../AGENTS.md) → Agent verification gates**—cite that section instead of copying long policy here.

## Trunk CLI resolution

Resolve how you invoke Trunk **once** at the start of the loop:

1. If `trunk` is on `PATH` (`command -v trunk`), use **`make lint`** and **`make format`** (they call `trunk check -a` and `trunk fmt -a`).
2. Otherwise use the NPM launcher (same behavior as [Trunk install — NPM](https://github.com/trunk-io/docs/blob/main/code-quality/overview/cli/getting-started/install.md)): **`npx --yes @trunkio/launcher`** with the same subcommands and arguments as the CLI, for example:
   - `npx --yes @trunkio/launcher check -a`
   - `npx --yes @trunkio/launcher fmt -a`
   - `npx --yes @trunkio/launcher install` when managed linters are missing (`trunk install` equivalent).
3. When **`trunk` is missing**, **`make lint`** / **`make format`** will fail—use the **`npx …`** commands above instead of Make for those steps until Trunk works.

**Cold runs:** On first use or large repos, run **`npx --yes @trunkio/launcher install`** (or `trunk install` when `trunk` exists) before a full **`check -a`** so downloads settle. Do not pipe **`trunk check`** to **`tail`** or similar until the process exits, or you may see no useful output for a long time.

## Loop Logic

1. **Identify**:
   - Run **`make lint`** **or** **`npx --yes @trunkio/launcher check -a`** per **Trunk CLI resolution**.
   - Run dead-code detection: **`make dead-code`** (alias **`make vulture`**, runs **`uv run vulture`** using `[tool.vulture]` in `pyproject.toml`). Fix unused code by removing it or using it—do not widen Vulture excludes unless the user asked for that policy change.
2. **Analyze**: Examine Trunk and Vulture output (path, line, message).
3. **Fix**:
   - For formatting, **`make format`** **or** **`npx --yes @trunkio/launcher fmt -a`**.
   - For lint findings, apply the minimum code change; resolve via code/types/imports/structure—not suppressions (see **Constraints**).
4. **Verify**:
   - Re-run lint (**`make lint`** / **`npx … check -a`**).
   - Re-run **`make dead-code`** until clean or only acceptable leftovers per project policy.
   - For type-only triage, **`uv run pyright`** reads `[tool.pyright]`; prefer Trunk for CI parity.
   - When fixes touched **executable code**, run **`make test`** after lint and Vulture pass (`dev/test_python.sh`; pytest-cov). Formatting- or comment-only edits may stop after lint + dead-code.
   - Repeat until clean or iteration limit.

## Constraints

- Do not silence Trunk/Ruff/Pyright/Pylint/Bandit/Semgrep findings with inline suppressions (for example `# noqa`, `# type: ignore`, `# pylint: disable`, `ruff: noqa`, file-level `# ruff: noqa`, or Trunk inline disable comments).
- Do not broaden project configuration to hide violations unless the user explicitly asked for that policy change.
- Prefer **`make format`** / **`npx … fmt -a`** for auto-fixable style; otherwise fix what the linter reports.
- If fixes fail after genuine attempts, stop and escalate—do not add suppressions to force green.

## Termination Criteria

- No errors from **`make lint`** (or equivalent **`npx … check -a`**).
- **`make dead-code`** succeeds (no unresolved dead-code per project expectations).
- When executable code changed: **`make test`** passes.
- Max iterations (default: 5).

## Examples

### Scenario: Fixing a formatting violation

1. Lint reports formatting issues in `src/your_package/main.py`.
2. Run **`make format`** (or **`npx … fmt -a`** if `trunk` is absent).
3. Lint and **`make dead-code`** pass.

### Scenario: `trunk` not on `PATH`

1. **`make lint`** fails with `trunk: command not found`.
2. Run **`npx --yes @trunkio/launcher install`**, then **`npx --yes @trunkio/launcher check -a`** and continue the loop with **`npx … fmt -a`** for formatting.

## Resources

- [Trunk Documentation](https://docs.trunk.io/)
- [Install Trunk CLI (including NPM launcher)](https://github.com/trunk-io/docs/blob/main/code-quality/overview/cli/getting-started/install.md)
- [pytest-cov](https://pytest-cov.readthedocs.io/) / [Coverage.py](https://coverage.readthedocs.io/)
