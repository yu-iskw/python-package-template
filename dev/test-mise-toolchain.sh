#!/bin/bash
# Smoke-test mise toolchain integration. Run from repo root after mise is installed.
set -Eeuo pipefail

SCRIPT_FILE="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "${SCRIPT_FILE}")"
MODULE_DIR="$(dirname "${SCRIPT_DIR}")"
cd "${MODULE_DIR}"

PASS=0
FAIL=0

assert() {
	local name="$1"
	shift
	if "$@"; then
		echo "PASS: ${name}"
		PASS=$((PASS + 1))
	else
		echo "FAIL: ${name}" >&2
		FAIL=$((FAIL + 1))
	fi
}

echo "=== mise toolchain smoke tests ==="

assert "mise.toml exists" test -f mise.toml
assert "mise.lock exists" test -f mise.lock
assert "mise on PATH" command -v mise
assert "mise trust" mise trust --yes "${MODULE_DIR}/mise.toml"
assert "mise install --locked" mise install --locked

assert "setup-tools.sh executable" test -x dev/setup-tools.sh
assert "mise-exec.sh executable" test -x dev/mise-exec.sh

assert "trunk via mise-exec" ./dev/mise-exec.sh trunk --version
assert "trivy via mise-exec" ./dev/mise-exec.sh trivy --version
assert "osv-scanner via mise-exec" ./dev/mise-exec.sh osv-scanner --version
assert "grype via mise-exec" ./dev/mise-exec.sh grype version
assert "codeql via mise-exec" ./dev/mise-exec.sh codeql version

TRIVY_VER="$(./dev/mise-exec.sh trivy --version 2>&1 | head -1)"
assert "trivy matches trunk.yaml (0.70.0)" grep -q '0.70.0' <<<"${TRIVY_VER}"

OSV_VER="$(./dev/mise-exec.sh osv-scanner --version 2>&1 | head -1)"
assert "osv-scanner matches trunk.yaml (2.3.8)" grep -q '2.3.8' <<<"${OSV_VER}"

assert "Makefile defines setup-tools" grep -q '^setup-tools:' Makefile
assert "Makefile defines MISE_EXEC" grep -q '^MISE_EXEC' Makefile
assert "mise-exec scopes to single tool" grep -q 'mise exec "${tool}@"' dev/mise-exec.sh

echo ""
echo "=== results: ${PASS} passed, ${FAIL} failed ==="
exit "${FAIL}"
