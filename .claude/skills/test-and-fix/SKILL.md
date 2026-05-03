---
name: test-and-fix
description: Run unit tests, coverage gates, and automatically fix code failures, regression bugs, missing tests, or test mismatches. Use when tests or coverage are failing, after implementing new features, or to repair "broken" tests.
---

# Test and Fix Loop

## Purpose

An autonomous loop for the agent to identify, analyze, and fix failing unit tests and coverage regressions using `pytest`, `pytest-cov`, and Coverage.py.

## Commands

- `make test` — default gate; runs the test suite with coverage and writes terminal, XML, JSON, and HTML coverage reports.
- `make test-unit` — fast unit-test-only run without coverage instrumentation.
- `make test-coverage COVERAGE_FAIL_UNDER=95` — strict configurable coverage gate.
- `uv run pytest path/to/test_file.py -q` — focused local reproduction for a specific failing test.

Coverage reports are written under `reports/coverage/`:

- `coverage.json` — preferred machine-readable report for agents.
- `coverage.xml` — CI and GitHub integration report.
- `html/` — local human inspection.
- terminal `term-missing` output — quick missing-line triage.

## Loop Logic

1. **Identify**: Run `make test` to identify failing tests or coverage threshold failures.
2. **Analyze tests**: Examine the `pytest` output to determine:
   - The failing test file and line number.
   - The expected vs actual values (assertion errors).
   - Tracebacks for runtime errors.
3. **Analyze coverage**: If tests pass but coverage fails, inspect the terminal missing-line report and `reports/coverage/coverage.json` to find uncovered branches, functions, and modules.
4. **Fix**:
   - Source code may be changed when the failure reveals a product bug.
   - Tests may be changed or added when behavior intent is clear and coverage is missing around meaningful behavior.
   - Do **not** raise/lower coverage thresholds or broaden omissions unless the user explicitly requests a policy change.
5. **Verify**: Re-run the narrowest useful command first, then `make test` before finishing.
   - If passed: Move to the next failing test or coverage gap, or finish if all are resolved.
   - If failed: Analyze the new failure and repeat the loop.

## Constraints

- Prefer behavior-focused tests over tests that only execute lines for coverage.
- Do not delete assertions or weaken expected behavior to make coverage or tests pass.
- Do not add `pragma: no cover` unless the code is genuinely untestable, defensive, or platform-specific and the user accepts that policy.
- Keep coverage source scoped to `src/your_package` unless project initialization has renamed the package.

## Termination Criteria

- All tests pass and the configured coverage gate passes (as reported by `make test`).
- Reached max iteration limit (default: 5).
- The error persists after multiple distinct fix attempts, indicating a need for human intervention.

## Examples

### Scenario: Fixing a logic error

1. `make test` fails in `src/your_package/tests/test_dummy.py` due to an assertion or import error.
2. Agent inspects the failing test and the implementation under `src/your_package/`.
3. Agent applies the minimum fix in source or test so behavior matches the intended contract.
4. `make test` passes.

### Scenario: Fixing a coverage regression

1. `make test` passes functionally but fails `COVERAGE_FAIL_UNDER`.
2. Agent inspects `reports/coverage/coverage.json` and terminal missing-line output.
3. Agent adds behavior-focused tests for uncovered meaningful branches.
4. `make test` passes with the configured threshold.

## Resources

- [Pytest Documentation](https://docs.pytest.org/): Official documentation for the pytest framework.
- [pytest-cov Documentation](https://pytest-cov.readthedocs.io/): Coverage integration for pytest.
- [Coverage.py Documentation](https://coverage.readthedocs.io/): Coverage measurement and reporting.
- Testing conventions for this repo: [AGENTS.md](../../../AGENTS.md) (Testing section).
