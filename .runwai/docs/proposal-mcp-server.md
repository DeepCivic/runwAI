# Proposal: runwAI as an MCP server

**Status:** proposed, not accepted. Nothing here changes the repository until a decision
record in [`../decisions.yaml`](../decisions.yaml) accepts it.

## The problem this solves

runwAI's value is the deterministic layer: the registry that maps 36 of 1101 ISM controls to
pinned tools, fourteen semgrep rules with fixtures asserting them both ways, `verify.py`'s
receipt, the offline dependency audit, and `security_report.py`'s refusal to round coverage
up. Today all of that reaches a project in one way only: **clone the template, then prune it.**

That delivery model has costs this repository already records:

- **It only works at birth.** An existing project cannot adopt runwAI without copying
  directories by hand, which decision 2 exists to forbid.
- **Updates do not propagate.** A rule fix or a new ISM release lands in this repository and
  in no project built from it. Every adopter is frozen at the commit they cloned.
- **The prune is the hardest step of the first session.** AGENTS.md step 4 is five edits
  across three files plus a manual link sweep, and backlog `id_10` shows that deleting
  `.runwai/` also deletes the validator that enforces the determinism invariant.
- **Maintainer and adopter content share a tree**, which is why AGENTS.md needs a scope
  section, decision 11, and a dot-directory nobody may cite.

An MCP server inverts this: the controls live in a versioned package, and a project only
holds a pin and its own outputs.

## The constraint that shapes everything

> AI may perform the setup work. The controls themselves must be deterministic.

An MCP server is, by construction, something a model calls. That is compatible with the
invariant only under three conditions, and the design below is built around them:

1. **The model chooses when to call a tool; it never produces the verdict.** No tool accepts
   a result, a severity or a pass/fail as input. Verdicts are computed by pinned code and
   returned as structured data.
2. **The committed artefacts are written by the engine, not by the model.** If the agent
   receives findings and writes `docs/security-report.md` itself, the report is model output
   wearing a generator's name. The server writes the file (or returns exact bytes plus a
   hash that `report --check` verifies).
3. **MCP is never the enforcement surface.** An agent can skip a tool call as easily as a
   human can pass `--no-verify`, and less visibly. The commit hook and CI must call the same
   engine without any model present. MCP is the delivery and explanation surface; the CLI
   is the enforcement surface.

Condition 3 is the one most likely to be lost in implementation, because "the AI runs the
checks" reads like coverage. It is not: a check that runs only when a model decides to has
measured nothing on every commit where it did not.

## Proposed architecture

One package, one version, three front-ends over one engine.

| Layer | What it is | Who calls it |
| :--- | :--- | :--- |
| **Engine** (`runwai.core`) | Registry, ISM snapshot and index, rule packs, fixtures, report builder, verify, audit, doctor — as functions returning structured results | The two front-ends below, never a model directly |
| **CLI** (`runwai ...`) | `check`, `verify`, `audit`, `doctor`, `report`, `report --check` — today's Makefile targets | pre-commit, CI, a human |
| **MCP server** (`runwai mcp`) | Tools, resources and prompts over the same engine, stdio transport | The adopter's agent |

The package version plus a content hash of its rule packs and registry is the provenance of
every verdict. Same package version, same tree, same database snapshot: same output.

### What a project holds afterwards

| File | Purpose |
| :--- | :--- |
| `.mcp.json` | Registers `runwai mcp` at an exact version. The path Claude Code and other MCP clients already read, so decision 2 is satisfied rather than overturned |
| `.pre-commit-config.yaml` | Calls `runwai check --staged` at the same exact version |
| `runwai.toml` | Pinned engine version, control pack, declared scope, any project-local rules or suppressions |
| `docs/security-report.md`, `docs/dependencies.md` | Generated, committed, as today |
| A CI workflow | Calls the CLI; reports and blocks nothing, as today |

Everything else in today's tree — `controls/`, `.github/scripts/`, `.runwai/tools/`, the rule
files, the fixtures — moves into the package. The adopter no longer receives the
maintainer's tooling, so backlog `id_10` and AGENTS.md step 4 stop existing rather than being
fixed.

### Version skew is the new failure mode

The hook, CI and the MCP server could run different engine versions and disagree. Mitigation:
all three read the version from `runwai.toml`; the CLI and server refuse to run on a mismatch
and say which pin to change; `doctor` reports the skew. This is a new check that does not
exist today because a cloned tree cannot skew against itself.

## MCP surface

Every tool result carries the same envelope, so the five states this repository already
distinguishes cannot collapse into a boolean:

```
status: pass | fail | not_applicable | not_run | could_not_run
receipt: { engine, rulepack_sha256, inputs_sha256, db_snapshot? }
```

`not_run` (environment-constrained, off) and `not_applicable` (no subject matter) are the
two the model is most likely to summarise as "clean". The tool descriptions and the result
text both say what each one leaves unknown.

### Tools

| Tool | Does | Network | Writes |
| :--- | :--- | :--- | :--- |
| `scan` | Rule packs over paths or the whole tree | No | No |
| `scan_secrets` | detect-secrets against the project baseline | No | No |
| `verify` | Rules against packaged fixtures, twice, identical verdicts required; canary secret | No | No |
| `applicability` | Which rule packs and ecosystems have subject matter in this tree — the AGENTS.md step 3 table, computed instead of asked | No | No |
| `coverage` | The report's ISM buckets (enforced / mapped / unassessed / out of scope) as data | No | No |
| `explain_control` | Registry entry, verbatim ISM text, mapping fidelity and notes for one control | No | No |
| `doctor` | Declared environment against actual, plus engine version skew | No | No |
| `audit` | trivy and syft offline against the cached snapshot; reports `not_run` with the reason when tools or database are absent | No | `docs/dependencies.md` |
| `setup_audit` | Fetch checksum-pinned trivy/syft and the database into a user cache | **Yes** | User cache only |
| `report` | Generate `docs/security-report.md` from engine results | No | `docs/security-report.md` |

`setup_audit` is the only networked tool and is marked so in its MCP annotations, so a
client can require confirmation. Every other tool is offline and read-only or writes only a
generated file.

### Resources and prompts

- **Resources:** `ism://control/{id}` (verbatim snapshot text, CC BY 4.0 attribution
  attached), `runwai://registry`, `runwai://rules/{pack}`, `runwai://fixtures/{pack}`.
  Verbatim text served by the engine removes the "quoted from memory" error class the
  maintainer guide records.
- **Prompts:** `first-session` (the adopter's setup conversation, rewritten for a project that
  already exists) and `explain-finding` (plain-language framing of one finding). These
  replace the parts of AGENTS.md that are about runwAI rather than the adopter's project.
  Prompts are guidance for the model; nothing in a prompt decides anything.

## What has to change in the engine first

The scripts are close to this already — offline, pinned, stdlib-plus-PyYAML, exit-code
disciplined — but three things block a clean extraction:

1. **The report contains the clock.** `security_report.py` writes
   `Generated <UTC time>` into the committed file, so two identical runs differ. Move the
   time into the receipt (or drop it) so the report body is a pure function of its inputs.
2. **Results exist only as Markdown and exit codes.** `verify.py`, `audit.py` and
   `doctor.sh` print prose. Each needs a function returning structured data, with the
   current prose rendered from it, so the CLI output is unchanged and the MCP result is
   not a parse of text meant for humans.
3. **`doctor.sh` is Bash.** Port it to Python so it runs inside the server on every platform
   an MCP client runs on, Windows included.

## Phasing

Each phase ships on its own and leaves the template working.

| Phase | Delivers | Done when |
| :--- | :--- | :--- |
| 0. Extract | `runwai.core` from today's scripts; the three changes above | `make verify` verdicts identical before and after; report byte-identical across two runs |
| 1. CLI | `runwai` on PyPI; Makefile and hook call it | Template's first session works with no `.github/scripts/` |
| 2. Read-only MCP | `coverage`, `explain_control`, `applicability`, resources | An agent in an unrelated project can answer "what does runwAI cover here" with no template files present |
| 3. Checks over MCP | `scan`, `scan_secrets`, `verify`, `doctor`, `report` | MCP and CLI produce identical receipts on the same tree |
| 4. Audit | `audit`, `setup_audit` with checksum-pinned binaries | `not_run` and `could_not_run` reported distinctly on a blocked network |
| 5. Slim the template | Template becomes `.mcp.json`, hook, `runwai.toml`, AGENTS.md; this repository becomes the package's home | Adopting runwAI into an existing project is one file plus one command |

## Risks

| Risk | Why it matters | Mitigation |
| :--- | :--- | :--- |
| The model paraphrases findings into something softer | The report's honesty is the product | The engine writes the file; `report --check` fails on any hand edit |
| Agent never calls the tools | Unmeasured reads as clean | Hook and CI call the CLI; MCP is never described as enforcing anything |
| The package becomes a supply-chain target | Every adopter trusts it with a hook that runs on commit | Exact pins only; PyPI trusted publishing with attestations; no auto-update path |
| Version skew between hook, CI and server | Two verdicts for one tree | One pin in `runwai.toml`; mismatch refuses to run |
| Remote/hosted server requested later | Uploading source to scan it is a data-handling decision, and a hosted service is not offline | Out of scope; stdio local only. Revisit only as its own decision |
| ISM text redistributed in a package | CC BY 4.0 requires attribution | Attribution in package metadata and on every `ism://` resource |
| Framework lock-in | MAINTAINERS.md says the method works with any baseline | Control packs as data (`ism-2026-06` first); no second pack until the first is extracted cleanly |

## What does not carry over

Stated so nobody infers coverage from the move:

- **Nothing becomes a merge gate.** The server blocks nothing; the hook remains the only
  thing that stops an action, and it is still bypassable.
- **Coverage does not grow.** Same 36 controls, same fourteen rules, same fidelity ratings.
  A wider distribution of the same checks is not more checks.
- **The root configs** (`biome.json`, `playwright.config.ts`, `promptfooconfig.yaml`) are not
  controls and have no place in the server. They stay a template concern or are dropped.

## Open questions for the maintainer

1. **Does the template survive?** Option A: keep it as a thin starter that wires the package.
   Option B: retire it and ship only the package plus an `init` command. Recommendation: A
   through phase 4, decide B with real adoption data.
2. **Can the server write into the repository?** Writing reports directly is what makes
   condition 2 hold. If a client or policy forbids writes, the fallback is bytes plus hash,
   and the agent writes — weaker, because the hash check then carries all the weight.
3. **Project-local rules.** Should adopters add their own semgrep rules through
   `runwai.toml`? If yes, the engine has to run the both-directions fixture check and the
   determinism validator on them, which is today's `validate_registry.py` becoming an
   adopter-facing feature rather than a maintainer one.
4. **Package and distribution name**, and whether PyPI is the only channel.
5. **Second framework.** In scope for this redesign, or explicitly deferred?
