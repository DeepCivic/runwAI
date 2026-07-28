# Running the checks

**The canonical list.** `AGENTS.md`, `README.md` and `agents/rules/reference-local-dev.md`
link here rather than restating these commands, because four copies of the same four
commands is four things to update when a path moves — which is exactly what happened when
the tools moved into `.runwai/tools/`.

Not to be confused with `.claude/commands/`, which are Claude Code slash commands. These
are shell commands. See "Two layers" in [README.md](README.md) for how those relate.

Every command here is offline and deterministic. None of them calls a model, and none
depends on the clock or the network — that is a property of the design, not a coincidence.

## Setup

```bash
pip install pre-commit==4.6.1
pre-commit install
```

The self-checks additionally need `pyyaml==6.0.3` and `jsonschema==4.26.0`.

The adopter-facing steps are also `Makefile` targets — `make first-session`, or `setup`,
`hook`, `check`, `verify` and `report` individually. The Makefile wraps the commands on
this page and adds none of its own, so this list stays canonical.

## The self-checks

```bash
python3 .runwai/tools/validate_registry.py     # structure, determinism invariant, pinning, provenance, overlap
python3 .runwai/tools/ism.py verify            # every ISM claim against controls/ism-snapshot.json
python3 .runwai/tools/validate_helpers.py      # AGENTS.md, agents/, root configs, llms.txt, .runwai/
python3 .runwai/tools/ism.py index --check     # the semantic index matches snapshot + tags
```

`validate_helpers.py` also takes optional file paths. They narrow the STEAL marker sweep to
those files and nothing else — every other check in it still runs against the whole tree.
Pre-commit passes the staged files that way so a commit does not re-read a tree it did not
touch. **Run it with no paths when you want the answer that counts**: the whole-tree sweep
is the only one that sees a marker added by a commit that skipped the hook, and it is how
the `posture` workflow and `report.py` invoke it.

Regenerate the index after editing `controls/ism-tags.yaml`:

```bash
python3 .runwai/tools/ism.py index             # writes controls/ism-index.json
```

Exit codes are uniform across all three:

| Code | Meaning |
| :--- | :--- |
| 0 | Passed. Warnings may still have printed. |
| 1 | One or more checks failed. |
| 2 | Could not run — missing dependency or unreadable input. |

Add `--strict` to treat warnings as failures. CI moves to `--strict` once the pending pins
in `.runwai/pinning.md` are complete; until then, warnings are expected.

## The checks that stop something

**Only one does, and it runs on your own machine.** `pre-commit` is the single place in
this repository where a check can prevent an action, and `--no-verify` walks past it. CI
reports; it does not block. Making a red check stop a merge is branch protection, a setting
on the repository rather than a file, and nothing here installs it.

```bash
pre-commit run --all-files             # everything the hook runs
pre-commit run runwai-semgrep --all-files    # one hook
```

Run a ruleset's fixtures, asserting each rule fires on the bad case and stays silent on the
good one:

```bash
semgrep --test --config controls/rules controls/tests
```

Scan the whole tree the way the pre-commit hook scans your staged files:

```bash
semgrep scan --error --metrics=off \
  --config controls/rules/injection.yaml \
  --config controls/rules/deserialisation.yaml \
  .
```

`--error` is what turns findings into a non-zero exit. Without it semgrep reports and exits
zero, which is the most common way a scanner ends up installed but enforcing nothing. The
`posture` workflow deliberately runs the same rulesets *without* `--error`, capturing the
findings to JSON for the report instead.

## Secret scanning

Two tools, split by where each can honestly run. `detect-secrets` is the commit hook and
comes with `pre-commit`, so there is nothing extra to install. `keyhog` runs in CI only.

To reproduce the CI scan locally you have to install keyhog first — it is a Rust binary,
not a pip package, and its own pre-commit hook is `language: system` for that reason:

```bash
curl -fsSL https://santh.dev/keyhog/install.sh | sh   # read it before you run it
keyhog scan . --backend cpu --severity medium         # what CI scans: the working tree
keyhog scan --git-history . --backend cpu --severity medium   # and reachable history
```

Exit codes are keyhog's own, and differ from everything else here: `0` clean, `1` findings,
`2` user error, `3` system error, `10` a credential verified live, `13` coverage incomplete.

**Do not pass `--verify`.** It calls vendor APIs to check which found credentials still
work. That makes the verdict depend on a third party's state at scan time, and it sends
candidate secrets off the machine — a scanner that exfiltrates what it finds is not a
control. It is off by default and CI sets it off explicitly.

If a run is noisy, record what is there rather than lowering the floor:

```bash
keyhog scan . --create-baseline keyhog-baseline.json
```

then pass it to the action's `baseline` input.

## The verification receipts

```bash
pip install semgrep==1.171.0 detect-secrets==1.5.0    # the pinned scanners it drives
python3 .github/scripts/verify.py                     # prove the checks catch what they claim
```

Adopter-facing, stdlib-only, offline. Runs every active rule against the committed
fixtures in both directions, twice (identical verdicts required); asserts the fixture
floor (three vulnerable and one safe case per rule, so an untested rule cannot pass
silently); and scans a fake credential generated at run time the way the commit hook
scans. Output is plain language with a fix per failure; exit codes follow the house
convention above. `--no-install-check` skips the commit-hook check — it is for CI,
where a checkout has no hooks. The `posture` workflow runs it on every push.

## The report

```bash
python3 .runwai/tools/report.py                # writes .runwai/report.md
python3 .runwai/tools/report.py --check        # fail if .runwai/report.md is stale
```

`.runwai/report.md` is generated, committed, and deliberately **timestamp-free**: regenerating it
on an unchanged tree produces a byte-identical file. A report carrying a timestamp produces
a diff on every run, so the diff stops carrying information and reviewers learn to ignore
the file — the same trap the `posture` workflow's secret-scan step already documents.

## The security report

```bash
python3 .github/scripts/security_report.py            # coverage only, no scanners
python3 .github/scripts/security_report.py \
  --findings semgrep.json --scan-scope "local, changed files"
```

Writes `docs/security-report.md`. Blocks nothing and has no staleness gate — it carries a
generation timestamp instead, so a stale copy says so on its face rather than failing a
build. Run without `--findings` and it says plainly that no scanner output was supplied,
which is not the same as nothing found.

The `posture` workflow runs it on every push and pull request, publishes it to the job
summary, and uploads it as an artifact.

## Verifying an upstream source

```bash
git ls-remote https://github.com/owner/repo HEAD          # resolve a commit SHA
git ls-remote --tags --refs https://github.com/owner/repo # list release tags
```

Use the git protocol, not `api.github.com`. The REST API is scoped to this repository and
returns 403 for `/repos/{owner}/{repo}` on anything else; `/search/*` is unavailable
entirely. Git has no such restriction.

To read a file from a large upstream repository without cloning all of it:

```bash
git clone --depth 1 --filter=blob:none --sparse https://github.com/owner/repo /tmp/x
git -C /tmp/x sparse-checkout set --no-cone '/AGENTS.md' '/LICENSE'
```

## Checking a tool version before pinning it

```bash
curl -s https://pypi.org/pypi/<package>/json | python3 -c "import json,sys; print(json.load(sys.stdin)['info']['version'])"
curl -s https://registry.npmjs.org/<package> | python3 -c "import json,sys; print(json.load(sys.stdin)['dist-tags']['latest'])"
```

PyPI and the npm registry are both directly reachable. A tag in `refs/tags` is **not** the
same as a confirmed release artifact — confirm the release before setting
`verified_version: true`.
