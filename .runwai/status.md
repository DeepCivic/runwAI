# Status and known limits

What is present in the template, and what is honestly known about it. Counts are checked
by `.runwai/tools/report.py`; the limits below are not, and are maintained by hand.

## Present

| | |
| :--- | :--- |
| Controls mapped | 35 (7 `direct`, 22 `partial`, 6 `supporting`) |
| ISM release | June 2026 — **all 35 IDs verified**, 0 fabricated |
| Capabilities | 7 |
| Rule tests | 10 rules across 2 rulesets, each asserted on both a failing and a passing case. TODO-14 retired the other two |
| AI helper layer | `AGENTS.md`, 11 agent rules, 1 skill — structure derived from upstream, licences verified |
| Adopter toolchain configs | 3, live at the root. Unexercised here: runwAI has no JS/TS |
| Vendored sources | 10, each pinned to a resolved 40-character commit SHA |
| Where checks run | `pre-commit` locally, which is the only thing that stops anything and is bypassable; `posture` in CI, which reports. No merge gate, by design |
| Secret scanning | Two tools by design: detect-secrets on the commit hook, keyhog 0.5.47 in CI over the tree and reachable history. Live verification off |

## Limits, deliberately visible

**Most mappings are `partial`.** The ISM is not a CI specification. Of 35 controls only 7
are `direct` — the tool enforces exactly what the control requires. `partial` means it
covers part of it; `supporting` means it produces evidence but does not satisfy the
control. Only `direct` mappings should be described to an assessor as enforced. See
[`../docs/ism-verification.md`](../docs/ism-verification.md).

**Eight tools are unpinned.** grype, cosign, trivy and hadolint ship as GitHub release
binaries whose versions could not be confirmed where this was authored. They are recorded
with **no version at all** rather than a guessed one — pinning a scanner to a version
nobody checked is the same class of error as citing an unverified control ID. None of them
runs anywhere yet, so no check depends on the missing pins. gitleaks was the ninth and is
gone: keyhog replaced it at a resolved commit with its licence read from the upstream tree.
See [`pinning.md`](pinning.md).

**The AI helper layer is derived, not original.** `AGENTS.md`, `agents/` and the root
toolchain configs are adapted from a small set of upstream projects, each recorded with
a resolved commit SHA and its upstream licence in [`provenance.md`](provenance.md). This
replaced a 62-entry research inventory: ten sources that were actually used and verified,
instead of sixty-two that were not.

**The three root toolchain configs are unexercised.** runwAI is Python, YAML and Markdown,
so nothing here runs Biome, Playwright or promptfoo: a mistake inside one of those configs
fails no check in this repository. They ship live at the root regardless, because that is
where the adopter's tools read them and a file nobody knows to copy is a file nobody uses
([decision 2](decisions.yaml)). What is enforced is that
each parses, declares an exact version, and agrees with the version table in `README.md`;
`playwright.config.ts` is additionally in scope for our own semgrep rulesets. Run them in a
real project before relying on them.

**The commit-time gate is heavier than its design intends.** The stated shape is fast
checks on save and the full set at the merge boundary, with a leaked credential the one
thing worth stopping a commit for. `pre-commit` today runs seven blocking hooks — SAST, the
registry self-check, ISM verification, the ISM index check, the helper-layer check and a
report-freshness check alongside the secret scan — which makes saving your work the
heaviest gate rather than the lightest. That is a gate placed in the wrong place, not a
weakened one: nothing was moved after it failed. Rebalancing it is TODO-9 in
[`backlog.yaml`](backlog.yaml).

## Verification discipline

This repository's history contains two classes of error, both of which look like competent
work until checked. Plausible ISM control IDs that were never read — four mappings in the
original draft were disproved by reading the authoritative text. And repository slugs
asserted without resolution — a 62-entry inventory was deleted rather than verified, several
entries being fabricated.

The pattern in both is fluent output about something nobody checked. If a claim cannot be
verified, say so and mark it unverified. That is always the cheaper outcome.
