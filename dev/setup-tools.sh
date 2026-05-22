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
	echo "Error: 'mise' is not on PATH."
	echo "Install mise: https://mise.jdx.dev/getting-started.html"
	echo "  curl https://mise.run/install.sh | sh"
	exit 1
fi

mise trust --yes "${MODULE_DIR}/mise.toml" 2>/dev/null || mise trust "${MODULE_DIR}"

LOCK_ARGS=()
if [[ -f "${MODULE_DIR}/mise.lock" ]]; then
	LOCK_ARGS=(--locked)
fi

echo "--- Installing toolchain via mise (mise.toml + mise.lock) ---"
mise install "${LOCK_ARGS[@]}"

echo "--- Installing Trunk-managed linters (trunk install) ---"
mise exec -- trunk install

echo "--- Toolchain versions ---"
mise exec -- trunk --version
mise exec -- trivy --version
mise exec -- osv-scanner --version
mise exec -- grype version
mise exec -- codeql version
