---
name: lint-and-fix
description: Run linters, complexity gates, and fix violations, formatting errors, style mismatches, or maintainability issues using Trunk, Ruff, Xenon, and Radon. Use when code quality checks fail, before submitting PRs, or to repair "broken" linting states.
---

# Lint and Fix Loop: Trunk + Complexity

## Purpose

An autonomous loop for the agent to identify, fix, and verify linting, formatting, typing, security, and complexity violations using Trunk plus explicit Xenon/Radon complexity guardrails.

## Commands

- `make lint` — default gate; runs `trunk check -a` and the Xenon complexity gate.
- `make format` — auto-format code through Trunk.
- `make complexity` — focused Xenon cyclomatic-complexity gate.
- `make complexity XENON_MAX_ABSOLUTE=A` — strict complexity gate.
- `make complexity-report` — detailed Radon cyclomatic-complexity, maintainability-index, and raw-metrics JSON reports under `reports/complexity/`.

## Loop Logic

1. **Identify**: Run `make lint` to list current Trunk and complexity violations.
2. **Analyze lints**: Examine Trunk output, focusing on file path, line number, and error message.
3. **Analyze complexity**:
   - For a failing gate, inspect Xenon output first.
   - Run `make complexity-report` when the agent needs JSON reports or maintainability/raw metrics to plan refactors.
   - Treat Ruff `C901` as the fast lint signal and Xenon/Radon as the detailed complexity signal.
4. **Fix**:
   - For formatting issues, run `make format`.
   - For linting violations, apply the minimum necessary change to resolve the reported issue.
   - For complexity violations, refactor into smaller functions, extract helpers, flatten nested conditionals, simplify branching, or replace repeated logic with data-driven structure.
   - Resolve findings by changing code, types, imports, or structure—not with suppressions (see **Constraints**).
5. **Verify**: Re-run the narrowest useful command first, then `make lint` before finishing.
   - For type-only triage, `uv run pyright` also reads `pyproject.toml` `[tool.pyright]`; prefer Trunk for CI parity.
   - If passed: Move to the next issue or finish if all are resolved.
   - If failed: Analyze the new failure and repeat the loop.

## Constraints

- Do not silence Trunk/Ruff/Pyright/Pylint/Bandit/Semgrep findings with inline suppressions (for example `# noqa`, `# type: ignore`, `# pylint: disable`, `ruff: noqa`, file-level `# ruff: noqa`, or Trunk inline disable comments).
- Do not broaden project configuration to hide violations (for example new `[tool.ruff.lint]` ignores, Pyright `report*` toggles, Pylint disables, or looser Xenon thresholds) unless the user explicitly asked for that policy change.
- Prefer `make format` for auto-fixable style; otherwise fix the underlying issue the linter reports.
- Prefer refactoring complexity over adding exceptions. Threshold changes are policy changes, not bug fixes.
- If fixes fail after genuine attempts, stop and surface the finding for a human to decide—do not add suppressions to make CI green.

## Termination Criteria

- No more errors reported by `make lint`.
- Reached max iteration limit (default: 5).

## Examples

### Scenario: Fixing a formatting violation

1. `make lint` reports formatting issues in `src/your_package/main.py`.
2. Agent runs `make format`.
3. `make lint` now passes.

### Scenario: Fixing a complexity violation

1. `make lint` fails in `make complexity` with a high-complexity function.
2. Agent runs `make complexity-report` and identifies the function's complexity and maintainability impact.
3. Agent extracts cohesive helper functions or simplifies branching without changing behavior.
4. Agent runs focused tests, then `make lint && make test`.

## Resources

- [Trunk Documentation](https://docs.trunk.io/): Official documentation for the Trunk CLI.
- [Xenon Documentation](https://radon.readthedocs.io/en/latest/commandline.html#xenon): Complexity gate built on Radon.
- [Radon Documentation](https://radon.readthedocs.io/): Python code metrics including cyclomatic complexity, maintainability index, and raw metrics.
