#!/bin/bash
# Run a command with mise-managed tools on PATH when mise.toml is present.
# Usage: dev/mise-exec.sh trunk check -a

set -Eeuo pipefail

SCRIPT_FILE="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "${SCRIPT_FILE}")"
MODULE_DIR="$(dirname "${SCRIPT_DIR}")"

cd "${MODULE_DIR}"

if command -v mise &>/dev/null && [[ -f "${MODULE_DIR}/mise.toml" ]]; then
	exec mise exec -- "$@"
fi

exec "$@"
