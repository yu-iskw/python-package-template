#!/bin/bash
# Run a command with a single mise-managed tool on PATH (avoids loading the full mise.toml toolchain).
# Usage: dev/mise-exec.sh <tool> [args...]
# Example: dev/mise-exec.sh trunk check -a

set -Eeuo pipefail

SCRIPT_FILE="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "${SCRIPT_FILE}")"
MODULE_DIR="$(dirname "${SCRIPT_DIR}")"

cd "${MODULE_DIR}"

if [[ $# -lt 1 ]]; then
	echo "Usage: mise-exec.sh <tool> [args...]" >&2
	exit 1
fi

if command -v mise &>/dev/null && [[ -f "${MODULE_DIR}/mise.toml" ]]; then
	tool="$1"
	shift
	exec mise exec "${tool}@" -- "${tool}" "$@"
fi

exec "$@"
