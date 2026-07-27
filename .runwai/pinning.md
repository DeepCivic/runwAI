# Tool pinning status

Every control in `controls/registry.yaml` names the tools that enforce it, pinned to
an exact version. An unpinned scanner is a non-deterministic control by definition —
its ruleset can change under you and silently alter verdicts — so
`.runwai/tools/validate_registry.py` rejects floating specifiers (`latest`, `*`, `^`, `~`,
bare major tags).

## Verified pins

These versions were confirmed to exist at the time of writing. Everything except keyhog
is installed from PyPI directly rather than through third-party marketplace actions, which
keeps the trusted surface to one registry and the pins reviewable in one place.

| Tool | Version | Class | Controls |
| :--- | :--- | :--- | :--- |
| keyhog | 0.5.47 | secret-scan | RWA-0010 |
| semgrep | 1.171.0 | sast | RWA-0002, 0003, 0011, 0012, 0020–0026, 0041, 0060, 0061, 0073, 0074 |
| checkov | 3.3.8 | iac-scan, config-scan | RWA-0005, 0011, 0040, 0041, 0042, 0061 |
| detect-secrets | 1.5.0 | secret-scan | RWA-0002, 0010, 0071 |
| bandit | 1.9.4 | sast | RWA-0003, 0012, 0060 |
| cyclonedx-bom | 7.3.1 | sbom, cbom | RWA-0003, 0032, 0033, 0034, 0062 |
| sslyze | 6.3.1 | tls-scan | RWA-0041 |
| schemathesis | 4.24.2 | schema-test, dast | RWA-0072 |
| presidio-analyzer | 2.2.364 | pii-filter | RWA-0071 |
| garak | 0.15.1 | ai-fuzz | RWA-0070 |

### How the keyhog pin was verified, and what could not be

keyhog is the one entry not installed from PyPI, so its receipt is recorded rather than
assumed. It replaced gitleaks, which sat in the pending table below for the life of the
template because its release list was unreachable from here.

| Claim | How it was checked |
| :--- | :--- |
| Repository | `santhreal/keyhog`, per the `repository` field in the upstream `Cargo.toml`. `santhsecurity/keyhog` resolves to the same HEAD, so it is a rename, not a second publisher |
| Version `0.5.47` | `version` in `Cargo.toml` at HEAD, matching tag `v0.5.47` |
| Commit | Tag `v0.5.47` resolves to `19bb6b0945584ff28341e4fd5e7a32c1b90602c7`. Lightweight tag, so that is the commit, and it is what `.github/workflows/posture.yml` pins |
| Licence `MIT OR Apache-2.0` | Read from `LICENSE`, `LICENSE-MIT` and `LICENSE-APACHE` in a sparse checkout of that tree — not from the README, and not from memory |

**`cargo install keyhog` is documented upstream and is NOT verified here.** `crates.io`
refuses `CONNECT` from this environment with a 403, so the crate's existence and version
could not be confirmed the way the PyPI pins above were. That is a limit of where this was
authored, not a finding about the crate — but an unchecked claim does not go in a pinning
table, so the GitHub Action pin, resolved over the git protocol, is what ships. Anyone with
crates.io reachable can confirm it and add the row.

## Pending verification

These are recorded in the registry as `install: unavailable` with **no version**,
which the validator reports as a warning. They carry no invented version number
deliberately: pinning a tool to a version nobody confirmed is the same class of error
as citing an unverified control ID.

| Tool | Class | Controls | Why unpinned |
| :--- | :--- | :--- | :--- |
| grype | sca | RWA-0031 | GitHub release binary |
| cosign | signing | RWA-0035, RWA-0036 | GitHub release binary |
| trivy | container-scan | RWA-0051 | GitHub release binary |
| hadolint | container-lint | RWA-0050 | GitHub release binary |
| coverage | coverage-gate | RWA-0024 | Language-specific; needs one ruleset per ecosystem |
| branch-protection-audit | config-scan | RWA-0001 | Forge API script, not yet written |
| codeowners-audit | config-scan | RWA-0004 | Forge API script, not yet written |
| lockfile-registry-audit | config-scan | RWA-0030 | Not yet written |

### Completing a pin

1. Confirm the release exists and note the exact tag.
2. Record the version and `verified_version: true` in `controls/registry.yaml`, and
   change `install` from `unavailable` to the real method.
3. Move the row from this section to the table above.
4. Run `python3 .runwai/tools/validate_registry.py` — the warning for that tool should clear.

Once every pin is verified, CI can move to `--strict`, which fails on warnings.

## Also pending: checkov check IDs

checkov and its allowlist were deleted by TODO-15. What follows records what the audit
found while they existed: the config listed check IDs selected
against the control text but not confirmed against checkov's own registry. **Checkov
silently ignores an unknown check ID**, so a misspelling means a control you believe is
enforced simply does not run.

An `iac` job used to verify this by diffing the claimed IDs against `checkov --list`. It
went with the workflow it lived in, and nothing verifies check IDs today. Recorded here so
that whoever reintroduces checkov reintroduces the verifier with it — and reads the defect
in `backlog.yaml` first, because that verifier's own regex could not match `CKV_K8S_19`.

## GitHub Actions pins

The workflows use `actions/checkout@v4`, `actions/setup-python@v5` and
`actions/upload-artifact@v4` — first-party actions at stable major tags. Pinning
actions to a commit SHA is stricter and worth doing if runwAI is used in an
environment where the ISM's cyber supply chain controls (ISM-1568, ISM-1787) are being
assessed against the pipeline itself.
