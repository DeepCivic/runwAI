# runwAI — the first session's mechanical steps, as deterministic targets.
#
# `make first-session` replicates what AGENTS.md tells the setup agent to run: install
# the pinned toolchain, install the commit hook, run every check over the whole tree,
# prove the rules catch their committed fixtures, and regenerate the security report.
# An agent transcribing commands from prose is where a wrong flag or a stale pin slips
# in; a target is the same command every time.
#
# Each target wraps exactly one documented step and adds nothing of its own — the
# canonical command list, with exit codes and what each check covers, stays in
# agents/running-the-checks.md. Every version below is pinned: `setup` needs the network
# once, and everything after it is offline, deterministic, and calls no model.

PYTHON ?= python3

.PHONY: first-session setup hook check verify report

first-session: setup hook check verify report

setup: ## Install the pinned toolchain (the one step that needs the network)
	$(PYTHON) -m pip install pre-commit==4.6.1 semgrep==1.171.0 detect-secrets==1.5.0 pyyaml==6.0.3

hook: ## Install the commit hook — the only thing here that ever stops an action
	pre-commit install

check: ## Run every commit-time check, over the whole tree rather than staged files
	pre-commit run --all-files

verify: ## Prove each rule catches its committed vulnerable examples — the receipt for IT
	$(PYTHON) .github/scripts/verify.py

report: ## Regenerate docs/security-report.md (coverage only; CI adds scan findings)
	$(PYTHON) .github/scripts/security_report.py
