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

REPORTS_DIR ?= reports
PACKAGE_DIR ?= src/your_package
TEST_DIR ?= src/your_package/tests
COVERAGE_FAIL_UNDER ?= 85
XENON_MAX_ABSOLUTE ?= B
XENON_MAX_MODULES ?= A
XENON_MAX_AVERAGE ?= A

# Set up an environment
.PHONY: setup
setup: setup-python

# Set up the python environment.
.PHONY: setup-python
setup-python:
	bash ./dev/setup.sh --deps "development"

# Upgrade Python dependencies (refresh uv.lock, then sync like development setup).
.PHONY: upgrade-deps
upgrade-deps:
	uv lock --upgrade
	uv sync --all-extras

# Check all the coding style and complexity guardrails.
.PHONY: lint
lint:
	trunk check -a
	$(MAKE) complexity

# Format source codes
.PHONY: format
format:
	trunk fmt -a

# Find unused code (Vulture; reads [tool.vulture] in pyproject.toml).
.PHONY: dead-code vulture
dead-code vulture:
	uv run vulture

# Run the unit tests without coverage instrumentation.
.PHONY: test-unit
test-unit:
	bash ./dev/test_python.sh

# Run tests with configurable coverage gates and agent-readable reports.
.PHONY: test-coverage
test-coverage:
	mkdir -p $(REPORTS_DIR)/coverage
	uv run pytest -v -s --cache-clear \
		--cov=$(PACKAGE_DIR) \
		--cov-report=term-missing:skip-covered \
		--cov-report=xml:$(REPORTS_DIR)/coverage/coverage.xml \
		--cov-report=json:$(REPORTS_DIR)/coverage/coverage.json \
		--cov-report=html:$(REPORTS_DIR)/coverage/html \
		--cov-fail-under=$(COVERAGE_FAIL_UNDER) \
		$(TEST_DIR)

# Run the unit tests with the default coverage gate.
.PHONY: test
test: test-coverage

# Check cyclomatic complexity gate with Xenon.
.PHONY: complexity complexity-xenon
complexity complexity-xenon:
	uv run xenon --max-absolute $(XENON_MAX_ABSOLUTE) --max-modules $(XENON_MAX_MODULES) --max-average $(XENON_MAX_AVERAGE) $(PACKAGE_DIR)

# Produce detailed Radon complexity, maintainability, and raw metric reports.
.PHONY: complexity-report
complexity-report:
	mkdir -p $(REPORTS_DIR)/complexity
	uv run radon cc --show-complexity --total-average --json $(PACKAGE_DIR) > $(REPORTS_DIR)/complexity/radon-cc.json
	uv run radon mi --show --json $(PACKAGE_DIR) > $(REPORTS_DIR)/complexity/radon-mi.json
	uv run radon raw --json $(PACKAGE_DIR) > $(REPORTS_DIR)/complexity/radon-raw.json
	uv run radon cc --show-complexity --total-average $(PACKAGE_DIR)

# Run local CodeQL analysis.
.PHONY: codeql
codeql:
	bash ./dev/codeql.sh

# Build the package
.PHONY: build
build:
	bash -x ./dev/build.sh

# Clean the environment
.PHONY: clean
clean:
	bash ./dev/clean.sh

all: clean lint test build

# Publish to pypi
.PHONY: publish
publish:
	bash ./dev/publish.sh "pypi"

# Publish to testpypi
.PHONY: test-publish
test-publish:
	bash ./dev/publish.sh "testpypi"

.PHONY: scan-vulnerabilities
scan-vulnerabilities:
	trivy fs .
	osv-scanner scan -r .
	grype .
