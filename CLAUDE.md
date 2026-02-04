# Python Package Template - Claude Code Memory

## Project Overview

This is a production-ready Python package template using modern tooling:
- **Package Manager**: uv (fast Python package manager)
- **Build System**: Hatchling
- **Linting/Formatting**: Trunk (manages Ruff, Mypy, Black, isort, Pylint, Bandit)
- **Testing**: pytest
- **Python**: 3.10+ (see `.python-version` for current version)

## Quick Commands

```bash
make setup      # Install dependencies and set up environment
make lint       # Run all linters via Trunk
make format     # Auto-format code via Trunk
make test       # Run pytest test suite
make build      # Build the package
make clean      # Clean build artifacts
```

## Code Style

- Follow Google Python Style Guide (configured in `.pylintrc`)
- Use type hints for all public functions
- Imports sorted by isort (stdlib, third-party, local)
- Max line length: 100 characters (Ruff/Black configured)
- Use `snake_case` for functions/variables, `PascalCase` for classes

## Testing

- Write tests in `tests/` directory
- Test files must match pattern `test_*.py`
- Run `make test` before committing
- Aim for meaningful test coverage on critical paths

## Git Workflow

- Create feature branches from `main`
- Run `make lint && make test` before commits
- Commit messages: `type(scope): description` (e.g., `feat(api): add user endpoint`)
- Types: feat, fix, docs, style, refactor, test, chore

## Architecture

- Source code in `src/your_package/` (rename during initialization)
- Development scripts in `dev/`
- CI/CD workflows in `.github/workflows/`
- Claude Code configuration in `.claude/`

## Common Gotchas

- Always use `uv run` to execute commands in the virtual environment
- Trunk manages tool versions hermetically - don't install linters globally
- The `uv.lock` file is committed for reproducibility - don't gitignore it
- Run `trunk install` if linters report missing tools

## Self-Improvement

This project supports Claude Code self-improvement. When you notice:
- Repeated mistakes Claude makes, add rules to this file
- New workflows you explain often, create skills in `.claude/skills/`
- Patterns that should be automated, add hooks in `.claude/settings.json`

Use `/improve-claude-config` skill to help Claude evolve its own configuration.
