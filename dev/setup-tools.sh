#!/bin/bash
# Copyright 2025 yu-iskw
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -Eeuo pipefail

SCRIPT_FILE="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "${SCRIPT_FILE}")"
MODULE_DIR="$(dirname "${SCRIPT_DIR}")"

cd "${MODULE_DIR}"

if ! command -v mise &>/dev/null; then
	echo "Error: 'mise' is not on PATH (required for make setup-tools and make setup)." >&2
	echo "Install mise first: https://mise.jdx.dev/getting-started.html" >&2
	echo "  Or use only Python setup: make setup-python" >&2
	exit 1
fi

# CodeQL in mise.lock uses the x64 zip for linux-arm64; the binary does not run natively on ARM64 Linux.
codeql_os="$(uname -s)"
codeql_arch="$(uname -m)"
codeql_run_version_check=true
if [[ ${codeql_os} == "Linux" && (${codeql_arch} == "aarch64" || ${codeql_arch} == "arm64") ]]; then
	codeql_run_version_check=false
fi

mise trust --yes "${MODULE_DIR}/mise.toml" 2>/dev/null || mise trust "${MODULE_DIR}"

LOCK_ARGS=()
if [[ -f "${MODULE_DIR}/mise.lock" ]]; then
	LOCK_ARGS=(--locked)
fi

echo "--- Installing toolchain via mise (mise.toml + mise.lock) ---"
mise install "${LOCK_ARGS[@]}"

echo "--- Installing Trunk-managed linters (mise run trunk-install) ---"
mise run trunk-install

echo "--- Toolchain versions ---"
mise exec trunk@ -- trunk --version
mise exec trivy@ -- trivy --version
mise exec osv-scanner@ -- osv-scanner --version
mise exec grype@ -- grype version
if [[ ${codeql_run_version_check} == "true" ]]; then
	mise exec codeql@ -- codeql version
else
	echo "codeql: version check skipped on Linux ARM64 (mise.lock provides x64 bundle only)." >&2
	echo "  Install still succeeds; use x64 Linux/macOS for make codeql." >&2
fi
