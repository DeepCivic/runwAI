# runwAI — the first session's mechanical steps, as deterministic targets.
#
# `make first-session` replicates what AGENTS.md tells the setup agent to run: install
# the pinned toolchain, install the commit hook, run every check over the whole tree,
# prove the rules catch their committed fixtures, audit the dependencies, check the
# environment, and regenerate the security report. An agent transcribing commands from
# prose is where a wrong flag or a stale pin slips in; a target is the same command
# every time.
#
# Each target wraps exactly one documented step and adds nothing of its own — the
# canonical command list, with exit codes and what each check covers, stays in
# agents/running-the-checks.md. Every version below is pinned: `setup`,
# `setup-audit-tools` and `setup-audit-dbs` need the network, and everything after them
# is offline, deterministic, and calls no model.

PYTHON ?= python3

# The dependency scanners ship as release binaries rather than packages, so the pin has
# to name a version, a platform and a checksum. Pinning to the tag alone would trust
# whatever the release assets are today; the checksum is what makes the install
# reproducible. Both are Apache-2.0, read from LICENSE in each upstream tree at the tag
# below. Change these and you are changing a control's tooling — see MAINTAINERS.md.
TRIVY_VERSION ?= 0.72.0
SYFT_VERSION ?= 1.50.0
#
# The four allowlist pragmas below are the one place in this repository where a secret
# scanner is told to stand down, so the reason is here rather than implied: these are
# published artefact digests from each release's own checksums.txt. A SHA-256 of a public
# tarball is high-entropy hex and nothing else — detect-secrets cannot tell it from a key,
# and suppressing it in the baseline instead would hide it from review.
#
# Make ends a variable's value at the '#', but keeps the space before it, so each value
# below carries a trailing space. `$(strip ...)` at the use site removes it — sha256sum
# tolerates the extra space today and there is no reason to depend on that.
TRIVY_SHA256_amd64 ?= bbb64b9695866ce4a7a8f5c9592002c5961cab378577fa3f8a040df362b9b2ea # pragma: allowlist secret
TRIVY_SHA256_arm64 ?= 2ca2c023109c2db6b2b77366b6717291452d4531167377d95c79547f0c8e3467 # pragma: allowlist secret
SYFT_SHA256_amd64 ?= bf7b29ff57f06da30918266a0e1c2885a8f99784798d1bdb1628886aa015d788 # pragma: allowlist secret
SYFT_SHA256_arm64 ?= 887c57cbcc2d0e8c5c110a4571a3fc7150058b24d74f993ee4663516e5c8ce86 # pragma: allowlist secret
AUDIT_BIN ?= .audit-cache/bin

.PHONY: first-session setup hook check verify report audit doctor \
        setup-audit-tools setup-audit-dbs

# audit and doctor run last and are not allowed to abort the session. Both report on
# things a first session cannot be expected to have got right yet — a dependency with a
# CVE, an unset environment variable — and neither is a reason to stop setting up.
first-session: setup hook check verify report
	@$(MAKE) --no-print-directory audit || true
	@$(MAKE) --no-print-directory doctor || true

setup: ## Install the pinned toolchain (the one step that needs the network)
	$(PYTHON) -m pip install pre-commit==4.6.1 semgrep==1.171.0 detect-secrets==1.5.0 pyyaml==6.0.3

hook: ## Install the commit hook — the only thing here that ever stops an action
	pre-commit install

check: ## Run every commit-time check, over the whole tree rather than staged files
	pre-commit run --all-files

verify: ## Prove each rule catches its committed vulnerable examples — the receipt for IT
	$(PYTHON) .github/scripts/verify.py

audit: ## Scan dependencies for known CVEs and write the SBOM (offline; reports, never blocks)
	$(PYTHON) .github/scripts/audit.py

doctor: ## Compare the declared environment to the actual one (reports, never blocks)
	bash .github/scripts/doctor.sh

report: ## Regenerate docs/security-report.md (coverage only; CI adds scan findings)
	$(PYTHON) .github/scripts/security_report.py --audit .audit-cache/audit.json

# --- the two networked audit steps, kept separate from `setup` -----------------------
#
# Separate because they are large and because `make audit` must be honest about being
# offline. The database is roughly a gigabyte on disk; downloading it as part of every
# `setup` would make the first session slow for a project that may have no dependency
# manifests at all.

setup-audit-tools: ## Install trivy and syft at the pinned versions, checksum-verified
	@set -eu; \
	mkdir -p "$(AUDIT_BIN)"; \
	case "$$(uname -m)" in \
	  x86_64|amd64) \
	    trivy_arch=Linux-64bit; syft_arch=linux_amd64; \
	    trivy_sha=$(strip $(TRIVY_SHA256_amd64)); syft_sha=$(strip $(SYFT_SHA256_amd64)) ;; \
	  aarch64|arm64) \
	    trivy_arch=Linux-ARM64; syft_arch=linux_arm64; \
	    trivy_sha=$(strip $(TRIVY_SHA256_arm64)); syft_sha=$(strip $(SYFT_SHA256_arm64)) ;; \
	  *) echo "unsupported architecture $$(uname -m); install trivy and syft by hand" >&2; exit 2 ;; \
	esac; \
	tmp=$$(mktemp -d); \
	curl -fsSL -o "$$tmp/trivy.tgz" \
	  "https://github.com/aquasecurity/trivy/releases/download/v$(TRIVY_VERSION)/trivy_$(TRIVY_VERSION)_$$trivy_arch.tar.gz"; \
	curl -fsSL -o "$$tmp/syft.tgz" \
	  "https://github.com/anchore/syft/releases/download/v$(SYFT_VERSION)/syft_$(SYFT_VERSION)_$$syft_arch.tar.gz"; \
	echo "$$trivy_sha  $$tmp/trivy.tgz" | sha256sum -c -; \
	echo "$$syft_sha  $$tmp/syft.tgz" | sha256sum -c -; \
	tar -xzf "$$tmp/trivy.tgz" -C "$(AUDIT_BIN)" trivy; \
	tar -xzf "$$tmp/syft.tgz" -C "$(AUDIT_BIN)" syft; \
	rm -rf "$$tmp"; \
	echo "trivy $(TRIVY_VERSION) and syft $(SYFT_VERSION) installed in $(AUDIT_BIN)/."; \
	echo "Add it to PATH:  export PATH=\"\$$PWD/$(AUDIT_BIN):\$$PATH\""

setup-audit-dbs: ## Download the vulnerability database once (the only network call `audit` needs)
	$(PYTHON) .github/scripts/audit.py --setup
