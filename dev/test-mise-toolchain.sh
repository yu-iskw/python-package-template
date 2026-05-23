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

codeql_os="$(uname -s)"
codeql_arch="$(uname -m)"
codeql_run_version_check=true
if [[ ${codeql_os} == "Linux" && (${codeql_arch} == "aarch64" || ${codeql_arch} == "arm64") ]]; then
	codeql_run_version_check=false
fi

echo "=== mise toolchain smoke tests ==="

assert "mise.toml exists" test -f mise.toml
assert "mise.lock exists" test -f mise.lock
assert "mise on PATH" command -v mise
assert "mise trust" mise trust --yes "${MODULE_DIR}/mise.toml"
assert "mise install --locked" mise install --locked

assert "no dev/mise-exec.sh wrapper" test ! -e dev/mise-exec.sh
assert "setup-tools.sh executable" test -x dev/setup-tools.sh

assert "mise.toml defines lint task" grep -q '^\[tasks\.lint\]' mise.toml
assert "mise.toml defines scan-vulnerabilities task" grep -q '^\[tasks\.scan-vulnerabilities\]' mise.toml

assert "trunk via mise exec" mise exec trunk@ -- trunk --version
assert "trivy via mise exec" mise exec trivy@ -- trivy --version
assert "osv-scanner via mise exec" mise exec osv-scanner@ -- osv-scanner --version
assert "grype via mise exec" mise exec grype@ -- grype version

if [[ ${codeql_run_version_check} == "true" ]]; then
	assert "codeql via mise exec" mise exec codeql@ -- codeql version
else
	echo "SKIP: codeql version on Linux ARM64 (x64 bundle in mise.lock)"
	PASS=$((PASS + 1))
fi

TRIVY_VER="$(mise exec trivy@ -- trivy --version 2>&1 | head -1)"
assert "trivy matches trunk.yaml (0.70.0)" grep -q '0.70.0' <<<"${TRIVY_VER}"

OSV_VER="$(mise exec osv-scanner@ -- osv-scanner --version 2>&1 | head -1)"
assert "osv-scanner matches trunk.yaml (2.3.8)" grep -q '2.3.8' <<<"${OSV_VER}"

assert "Makefile defines setup-tools" grep -q '^setup-tools:' Makefile
assert "Makefile uses mise run lint" grep -q 'mise run lint' Makefile
assert "Makefile has no MISE_EXEC" sh -c '! grep -q "^MISE_EXEC" Makefile'

echo ""
echo "=== results: ${PASS} passed, ${FAIL} failed ==="
exit "${FAIL}"
