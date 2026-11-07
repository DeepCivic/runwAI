# Proposal: runwAI as an ISM review MCP server

**Status:** proposed, not accepted. Nothing here changes the repository until a decision
record in [`../decisions.yaml`](../decisions.yaml) accepts it.

**Revision 2.** The first draft ported the template's machinery to MCP: one tool per
`make` target, with a CLI and the template kept as thin wiring. This revision is modelled
on `au-privacy-review` in `DeepCivic/civic-lab` (PR #4, branch `add-au-privacy-review`,
closed without merging, so treat it as a working design, not a released one). That server
already solves the problems the first draft only routed around, and runwAI's own
vocabulary — `not applicable`, `not run`, unassessed, mapping fidelity — fits its shape
almost exactly.

## The problem

runwAI's value is the deterministic layer: the registry mapping 36 of 1101 ISM controls to
pinned tools, the rule packs and their both-directions fixtures, `verify.py`'s receipt, the
offline dependency audit, and a report that refuses to round coverage up. Today it reaches
a project in one way only — clone the template, then prune it — so it works only for new
projects, never propagates a fix, and puts maintainer tooling in the adopter's tree
(backlog `id_10`).

There is a second problem the first draft missed entirely. **The report can say something
about 36 controls and nothing about the other 1065.** It counts them as unassessed or out of
scope and stops. That is honest, but it is a dead end: nobody is told what evidence would
move a control, and nothing can accept that evidence when it exists.

## What the privacy server does that runwAI should copy

### 1. One review call that needs no answers

`review_project(path, documents, observations)` reads what is there and returns, in one
result: findings by level, open questions (`gaps`), what was examined (`coverage`), where a
threshold assessment would land, and `report_markdown`. The individual scanners exist as
tools, but nobody has to orchestrate them.

**For runwAI:** `review_project` runs secrets, SAST, the audit (when its inputs are present),
and the ISM classification, and returns findings, gaps, coverage and the report. This
replaces `make first-session` and the eight-target table, which are orchestration an agent
should never have had to transcribe.

### 2. Observations: the agent records facts, the engine decides

The scanner cannot read PDFs, wikis, forge settings or what the team knows. The agent can.
It records each fact as `{kind, fact, source, present}` from a fixed vocabulary
(`list_observation_kinds`), and the next review treats it like a detector hit. Precedence is
explicit: team answer, then observation, then code evidence, then document mention — and a
"no" that contradicts code evidence is flagged as a conflict.

**This is the answer to the 1065 controls.** Branch protection (`RWA-0001`) is a forge
setting no file shows; an observation `{"kind": "branch_protection", "fact": "main requires
1 review and the posture check", "source": "GitHub settings, 2026-11-07"}` lets the engine
move that control out of unassessed. Hosting region, MFA on admin paths, an incident
runbook outside the repo — all are facts an agent can find and cite, and none is a verdict.

**It needs a decision, because it reads the invariant more finely than today.** The
invariant forbids a model *adjudicating* a control. An observation is model-*authored input*
with a citation; the mapping from observation to control state is pinned code. Same
observations, same tree, same verdict. What the report must never do is merge the tiers:

| Tier | Meaning | Ever described as enforced? |
| :--- | :--- | :--- |
| Checked | A pinned tool examined the tree and returned a verdict | Only where `mapping_fidelity: direct` |
| Evidenced | An observation with a source supports it; nothing re-checks it | No |
| Indicated | A document mentions it; nobody has confirmed what it says | No |
| Unassessed | Nothing examined | No |
| Not applicable / not run | No subject matter / check off on this machine | No |

### 3. Gaps that say what would settle them

Every open question carries why it matters, the evidence that would settle it, who usually
holds that evidence, the observation kinds that record it, and where the scan looked.
They come ranked, and the server's instructions tell the agent to answer what it can from the
material and ask the user only what is left.

**For runwAI:** unassessed controls become ranked gaps instead of a number. This is the
AGENTS.md obligation "never leave a failure they cannot interpret", implemented by the
server rather than left to whichever agent reads the guide.

### 4. Coverage as a first-class output

"Not detected" is claimed only about material that was examined; a review of documents alone
reports code-answerable questions as `unknown`. Unreadable files are listed, never skipped.

**For runwAI:** the same rule, already stated in prose, becomes a `coverage` field: which
ecosystems were audited, which rule packs had subject matter, which checks did not run on
this machine and why, the advisory database's snapshot date.

### 5. The workflow lives in the server, not in a guide the user must ship

`INSTRUCTIONS` on the server and two prompts (`privacy_review`,
`privacy_threshold_assessment`) carry the workflow: start here, read what the scanner cannot,
record observations, re-run, ask only what is left. Any MCP client gets that guidance with the
tools.

**For runwAI:** this is what lets the server work in *any* project. The "Who you are working
for" obligations and the step-3 rule-relevance table move into server instructions and a
`security_review` prompt. AGENTS.md stops being the delivery mechanism, and the
first-session prune, the `.runwai/` deletion and the scope section all go with it.

### 6. A compiled, verified knowledge base with a status tool

`kb.json` ships read-only. Every quotation is anchored to its source by `sha256(id + text)`
and character offsets, and the build fails on any quote it cannot find. `kb_status` reports
sources, versions, as-at dates, the build date and known limitations at run time.

**For runwAI:** `ism.py verify` already does the verification half. Compile
`ism-snapshot.json`, `ism-tags.yaml` and `registry.yaml` into one anchored knowledge base at
build time, and expose `kb_status`: ISM release, rule pack version, scanner pins, advisory
database snapshot date, and the limitations a user should know (36 of 1101, most `partial`;
nothing blocks a merge).

### 7. One `interrogate` tool

`interrogate(topic)` explains a finding, a question, an observation kind or a rule from the
same evidence as the review: evidence for and against, what was looked at, what would settle
it. **For runwAI:** replaces `.claude/commands/explain.md` and the explain skill.

### 8. Isolation and network off by default, as configuration

Paths outside `AU_PRIVACY_REVIEW_ROOTS` are refused; the one networked tool is off unless
`AU_PRIVACY_REVIEW_LIVE=1`; HTTP mode will not start without roots; the Docker image mounts
the project read-only at `/work` as an unprivileged user.

**For runwAI, this solves the environment-constrained audit.** trivy and syft are release
binaries that cannot bind to `.venv/`. A container image can carry them at their pinned
checksums, and the advisory database snapshot too, so the image tag *is* the snapshot date
decision 13 requires to be visible. On `uvx`, the audit stays `not_run` with the reason, as
now. Database refresh is a networked tool, off by default, mirroring `probe_deployment`.

### 9. The same engine in CI, and a monorepo that already ships servers

`au-privacy-review review . --fail-on high` is the CI entry point over the same code. Inline
`privacy-review: ignore` markers carry their reason in the comment. `civic-lab` already
discovers each `mcp-servers/*/pyproject.toml`, tests it on Linux, macOS and Windows,
launches it over stdio and lists its tools, publishes an image to ghcr.io and an entry to
the MCP Registry from `server.json`. `test_docs.py` fails when the docs and the code
disagree — the same idea as `validate_helpers.py`.

**For runwAI:** the hook and CI call the CLI; the agent calls the server; one package. The
commit hook stays the only thing that stops anything. MCP blocks nothing and the server
never claims to.

## What not to copy

- **The clock.** The privacy server defaults `as_at` to `date.today()` to decide whether a
  provision has commenced, so the same input can change verdict overnight. runwAI forbids a
  clock in a control. `as_at` must default to the knowledge base's build date and be
  reported, and `security_report.py`'s `Generated <time>` line moves out of the report body.
- **Precedent-based levels.** "Critical" there means the facts resemble a decided case. The
  ISM has no case law. runwAI's levels come from the rule's severity and the control's
  `mapping_fidelity`, and nothing is critical by analogy.
- **Floating dependency ranges.** `mcp>=1.22`, `httpx>=0.27`. runwAI pins exactly; the
  package must too, with a lockfile.
- **`--fail-on` as a gate in the report's vocabulary.** A CI exit code that fails a job still
  blocks no merge without branch protection. The CLI can offer it; the docs must say that.

## Proposed surface

| Tool | Does | Network |
| :--- | :--- | :--- |
| `review_project` | **Start here.** Secrets, SAST, audit if inputs present, ISM classification, observations. Returns findings, gaps, coverage, tiers, `report_markdown` | No |
| `interrogate` | One finding, control, gap, rule or observation kind, with evidence for and against | No |
| `list_observation_kinds` | The vocabulary, what to look for, which controls each bears on | No |
| `verify` | Rules against packaged fixtures twice, identical verdicts; the receipt for IT | No |
| `get_control`, `search_controls` | Verbatim ISM text, registry entry, fidelity, notes | No |
| `kb_status` | Versions, as-at dates, pins, database snapshot, limitations | No |
| `scan_repository` | Raw detector output without tiers | No |
| `refresh_advisories` | Download a new advisory snapshot. **Off unless enabled** | Yes |

Prompts: `security_review`, and `setup_project` for wiring the commit hook and CI into a
repository that has neither.

## What a project holds afterwards

An MCP client entry (`uvx` or the image), and optionally: the commit hook and CI step calling
the CLI at an exact version, an `observations.json` beside the code it describes, and the
generated `docs/security-report.md`. No template, no prune, no `.runwai/`.

## Phasing

| Phase | Delivers | Done when |
| :--- | :--- | :--- |
| 0. Extract | Scripts become an engine returning structured results; clock out of the report; `doctor.sh` ported to Python | `make verify` verdicts identical before and after; two runs give a byte-identical report |
| 1. Read-only server | `get_control`, `search_controls`, `kb_status`, `interrogate` over the compiled KB | Any MCP client can answer "what does this cover" with no template present |
| 2. Review | `review_project`, `scan_repository`, `verify`, CLI with the same engine | Server and CLI give identical results on the same tree |
| 3. Observations and gaps | The vocabulary, tiers, ranked gaps, precedence and conflicts | An observation moves `RWA-0001` to evidenced, never to checked; a contradicting one is flagged |
| 4. Image | trivy, syft and a dated advisory snapshot in the image; `refresh_advisories` off by default | The audit runs in the image with no network; on `uvx` it reports `not_run` with the reason |
| 5. Retire or slim the template | Decided with adoption data | — |

## Open questions

1. **Where it lives.** `civic-lab/mcp-servers/` gets cross-platform CI, the image and the
   Registry entry for free. runwAI keeps the history and the decisions. Recommendation:
   server in `civic-lab`, this repository as its design record and fixtures source until the
   template's future is decided.
2. **Observations and the invariant.** Accept the evidenced tier as model-authored input
   adjudicated by pinned code, with a decision record that says so — or keep runwAI to
   checked controls only and lose the route out of unassessed.
3. **The observation vocabulary.** Which unassessed ISM controls get kinds first. Proposal:
   the repository-adjacent ones (branch protection, CI permissions, hosting region, MFA on
   admin paths, incident runbook), because an agent can find and cite those.
4. **Image size.** Bundling the advisory database makes a ~1 GB image. Acceptable, or ship
   the image without it and keep the download as an opt-in tool?
