# runwAI — guide for AI agents

You are working in a **template repository for people building software with AI**. It maps
ISM controls to pinned, deterministic tools, ships the config files that enforce them, and
exists so that someone who is not a security engineer can understand what their code does
and does not satisfy.

## Decide which mode you are in, first

**A maintainer session is marked; an adopter session is not.** Work on runwAI itself opens
with **`#maintainer`** — or says in as many words that the subject is the template rather
than a product built from it. **Absent that marker, you are in adopter mode.** Do not infer
maintenance from the shape of a request: a question about a control, a rule or a failing
check is something an adopter asks about their own project far more often than it is someone
maintaining the template. If a prompt genuinely reads both ways, ask which — one short
question is cheaper than a session spent in the wrong mode.

**Building a product from this template.** The default, and the common case — this
repository exists to be used, not maintained. Read *Who you are working for*, *Your first
session* and *While you build*, then **stop at the horizontal rule**. Everything below it is
the template's own maintenance process. It is not your user's process, and applying it to
them is the single most likely way to waste their first session.

**Working on runwAI itself** — adding controls, rules or checks to the template. Start at
[`.runwai/MAINTAINERS.md`](.runwai/MAINTAINERS.md): it is the argument rather than the
index — what the template is for, which properties are load-bearing, and which decisions
should not be relitigated by accident. Then the whole of this file applies.

One invariant holds in both modes, and outranks everything else here:

> **AI may perform the setup work. The controls themselves must be deterministic.**

You may write controls, rules, configs, workflows and docs freely. You may **never** put a
model in the decision path of a control. A check may be *authored* by an agent; it may not
be *adjudicated* by one. `.runwai/tools/validate_registry.py` enforces this mechanically and
will fail the build if you violate it — so this is a rule you cannot talk your way past.

## Who you are working for

Assume your user is building a product, not studying security. They are capable and
non-technical. They will not know that `biome.json` at the root is theirs to edit or to
delete, that a check can be irrelevant to them, or that a passing build is not compliance —
so **they cannot prompt you to check those things. Doing it unprompted is your job.**

Three obligations follow, and they outrank convenience:

- **Volunteer the security implication, in plain language, without being asked.** If a
  change touches authentication, secrets, user data, network exposure or a dependency, say
  so in a sentence they can act on. Never make understanding the consequence depend on them
  asking the right follow-up question.
- **Never leave a failure they cannot interpret.** A red build with a check ID in it is not
  a report. Say what broke, what it means for their product, and what the options are.
- **Keep onboarding to one step.** They should not need to run a checklist to start. If a
  change adds a setup step for the user, find another way or say plainly why you could not.
  Anything you add for them ships **live, in the place its tool already looks** — never as
  a file they must first discover and copy. See
  decision 2 in [`.runwai/decisions.yaml`](.runwai/decisions.yaml).

## Your first session: setting this repository up

The user's likely first instruction is *"read `AGENTS.md`, then set this repository up for
me and tell me what it will and will not check."* Do the whole of this without further
prompting, and do it before writing any of their product code. It is short.

**1. Say what they have, in two or three sentences.** A template that just became their
repository: a commit hook that scans for credentials and a few classes of injection, and a
generated report describing where their code stands against a security baseline. Nothing
here blocks a merge. They do not need to read anything to continue.

**2. Install the hook.**

```bash
pip install pre-commit==4.6.1
pre-commit install
pre-commit run --all-files
```

That first full run may fail on files the template ships. Read the failure and fix or
explain it — do not tell them to re-run with `--no-verify`.

**3. Work out which of the three root configs they actually need.** They will not know
these are theirs to delete. Ask what they are building, then act.

| File | Job | Delete it when |
| :--- | :--- | :--- |
| `biome.json` | Formatting and linting for JavaScript and TypeScript | No JS/TS here, or a different formatter is in use |
| `playwright.config.ts` | Browser and end-to-end tests | There is no browser UI to test |
| `promptfooconfig.yaml` | Deterministic evals for prompts and agent tools | Nothing here calls a language model |

**Most projects need fewer than three, and deleting one is the correct action rather than a
compromise** — a config nobody runs rots quietly and misleads the next reader into thinking
something is checked. **A deletion is three edits in the same commit:** remove the file,
remove its row from the toolchain table in `README.md`, and remove its entry from
`llms.txt`. Then note it in [`docs/setup.md`](docs/setup.md) so a later reader knows it went
on purpose. `validate_helpers.py` fails on any of the three left behind — a documented file
that is not there is exactly the confident-index failure it exists to catch.

**4. Offer to delete `.runwai/`.** It is the template's own record — backlog, decisions,
provenance, pinning status, contribution guide — and it is about building runwAI, not about
building with it. Nothing in their project depends on it. **Do not read it in this mode, and
never cite it to the user:** runwAI's outstanding work is not their backlog and its
decisions are not theirs.

**If you delete it, prune what calls into it in the same commit** — the four `runwai-*`
hooks in `.pre-commit-config.yaml` that are not the secret scan, the `selfcheck` and
`python-sast` jobs in `.github/workflows/posture.yml`, and root `report.md`, which is the
output of `.runwai/tools/report.py` and describes runwAI's own self-checks rather than the
user's code. Those validate runwAI's own structure, so removing them loses the user
nothing. Leaving them behind gives them a check that fails on a missing file, and a stale
report about a directory that is gone — the worst of both.

**5. Write down what you did** in [`docs/setup.md`](docs/setup.md). It is the *adopting
project's* record and it is as-built: what is configured right now, not what someone decided
once. Keep it true in the same commit that changes the setup. Never record a decision about
the template itself there — that belongs in `.runwai/decisions.yaml`, and only in the other
mode.

**6. Make this file theirs.** `AGENTS.md` arrives describing runwAI — a template, its two
modes, and how to maintain it. The moment it is their repository that framing is wrong, and
an agent opening it next session will act on the wrong one. **Rewrite it in the same commit
as the rest of setup:**

- Replace the opening description with what *their* project is, in plain terms.
- **Delete everything below the horizontal rule, and the mode-selection section with it,
  if you deleted `.runwai/`.** That half is the template's maintenance process; it links
  into a directory that is now gone, and a dangling link in the file every future agent
  reads first is exactly the confident-index failure this repository refuses. A project
  with one mode does not need a fork in the road.
- **Keep *Who you are working for*, *While you build*, and the guardrails pointer.** Those
  describe how to work with this person, not how to maintain runwAI, and they are the
  reason the file is worth keeping at all.
- **Add what an agent cannot infer about their project**: how to run it, where the tests
  are, what it must never touch, which commands are safe unprompted.

Then tell them you have done it, in one line. They will not know this file governs every
later session, and it is the file most likely to rot silently — the cost of leaving it
describing a template lands on a future session, not this one.

**7. Tell them these four things unprompted**, because each is something they would
otherwise discover at the worst moment:

- **Nothing here can prevent a merge.** The commit hook is the only thing that stops an
  action, and `git commit --no-verify` walks straight past it. CI reports. Blocking a merge
  is branch protection — a setting at their forge that no template can switch on for them.
- **A green report is not compliance.** It means their code did not trip a set of automated
  checks. 35 of 1101 controls are mapped, most `partial`.
- **A check with nothing to look at is *not applicable*, not a pass.** Absent Terraform is
  not a finding and not a clean bill of health either.
- **They can ignore the control identifiers entirely** and the report still tells them what
  is checked and what is not.

## While you build

Once setup is done, most of this repository is scaffolding for their product and should stay
out of the way. What still holds:

- **The determinism invariant applies to anything you add for them.** If you write a check,
  it is an ordinary pinned program returning an exit code. Never an LLM verdict — no
  `llm-judge`, `ai-review` or `model-adjudication` tool class; the validator rejects them by
  name.
- **Never weaken a check to make CI green.** Fix the finding, or state plainly that you
  could not. Deciding *in advance* where a check runs is design; *moving* one after it fails
  is weakening it.
- **Never describe anything here as blocking a merge.** Nothing does, and claiming otherwise
  is the coverage lie this repository is built to refuse.
- **Never fail a project for lacking subject matter it was never going to have.** Report
  `not applicable` distinctly from a pass.
- **Never require the user to understand the ISM, or runwAI's vocabulary, to get a useful
  answer.**
- **Never use a floating version specifier** (`latest`, `*`, `^`, `~`, bare major tags), and
  never commit secrets, API keys or `.env` files.
- **Put a new check where it can actually see the problem.** Commit time is for what must
  never enter history — a leaked credential — and is the only place anything stops here.
  Anything structural, or needing the whole tree or full history, goes in
  `.github/workflows/posture.yml`, which reports.
- Use `rg` (ripgrep) for searching in preference to `grep`, and write comments that explain
  **why**, not **what**.

**When stuck:** ask a clarifying question before making large speculative changes — phrased
so someone non-technical can answer it, in terms of what they want their product to do
rather than which tool or schema field to use. Prefer stating "I could not verify this" over
producing a confident guess. If a gate fails and you do not understand why, report the
failure rather than routing around it.

## Running the checks

[`agents/running-the-checks.md`](agents/running-the-checks.md) is the canonical list — the
self-checks, the gates, exit codes, and how to verify an upstream source. It is not restated
here, because a command listed in four files is a command corrected in four files.

Two layers, and they are not alternatives. `AGENTS.md` and `agents/` are the canonical,
vendor-neutral content. `.claude/commands/*.md` are thin Claude Code adapters pointing into
it — a slash command only works from that path, so it lives there and holds no content of
its own. If you add a command, point it at `agents/` rather than restating the instructions.

## Security guardrails for LLM-integrated code

Not loaded by default, because not every change needs it. Read
[`agents/knowledge/llm-security-guardrails.md`](agents/knowledge/llm-security-guardrails.md)
when you are writing code that calls a model, handles model output, or exposes a prompt
surface.

---

# Working on runwAI itself

**Everything below this line is about maintaining the template, and you should be here only
on a `#maintainer` prompt.** If you are building a product from runwAI, you are finished —
none of it is your user's process. Start at
[`.runwai/MAINTAINERS.md`](.runwai/MAINTAINERS.md) before changing anything structural;
[`.runwai/README.md`](.runwai/README.md) indexes what else is in there.

## Do

- Run `python3 .runwai/tools/validate_registry.py` and `python3 .runwai/tools/ism.py verify` before
  concluding your work is finished
- Copy ISM control text **verbatim** from `controls/ism-snapshot.json`, never from memory
- Pin every tool to an exact version; if you cannot confirm a version exists, set
  `install: unavailable` and omit the version entirely
- Be pessimistic with `mapping_fidelity` — `partial` unless the tool enforces exactly what
  the control requires
- Assert every new rule in both directions in `controls/tests/`: it must fire on the bad
  case and stay silent on the good one. Name the fixture after the ruleset so
  `semgrep --test` pairs them
- Document a rule's known false-positive classes in a comment at the top of its rule file
- Make a new check **report `not applicable`** when the project has nothing for it to scan,
  distinctly from a pass. A check with no subject matter has found nothing, not nothing wrong
- Record `upstream.repo`, `upstream.commit` (full 40-char SHA) and `upstream.license` under
  the control's `implementation.provenance` for any vendored content, with a
  `LICENSE-UPSTREAM` beside the files
- Before finalising a commit, check whether any file you touched carries a `STEAL:` comment
  and update `.steal/manifest.md` in the *same* commit — path, two or three tags, one line
  of description, table sorted by path. See [`STEAL.md`](STEAL.md); `validate_helpers.py`
  fails the build when a blessed file has no row

## Don't

- Never invent an ISM control ID, a tool version, or a commit SHA. An unverified ID in an
  assessor-facing document is worse than no document.
- Never mark something `verified` without a `verification_source` and a `verified_on` date
- Never describe a passing build as compliant. 35 of 1101 controls are mapped, most
  `partial`; the honest claim is which checks ran and what they found
- Never claim content is vendored without recording its upstream licence
- Never scan `controls/tests/` with a normal scan — the fixtures contain deliberate
  vulnerabilities and are excluded in `.semgrepignore`

## Boundaries

### Always do
- Run both self-checks before pushing
- Read the control in `controls/ism-snapshot.json` before mapping a tool to it
- Update a control's `notes` and `mapping_fidelity` in the same commit that changes what it
  enforces

### Ask first
- Changing the structural rules in `.runwai/tools/validate_registry.py` — they are the
  enforcement surface now that `schemas/` is gone
- Adding a dependency, or changing a pinned version
- Changing an upstream pin, or re-resolving vendored content to a newer commit
- Deleting files, or relaxing any check in `.github/workflows/`

### Never do
- Commit secrets, API keys or `.env` files
- Put a model in a control's decision path
- Record a version, SHA or control ID you have not confirmed
- Force push or rebase shared branches

## Project structure

```
controls/registry.yaml        ISM control -> mechanism -> tool -> implementation
controls/ism-snapshot.json    All 1101 June 2026 ISM controls (CC BY 4.0)
controls/ism-tags.yaml        Our semantic tags. Edit here, then regenerate the index
controls/ism-index.json       Generated join of the three. Never edit by hand
security-report.md            The posture readout. Generated; blocks nothing
.github/scripts/              Its generator. Adopter-facing, so NOT in .runwai/
controls/rules/               The semgrep rulesets. Nine rules, two files
controls/tests/               Fixtures asserting each rule in both directions
docs/setup.md                 How this project is set up, as built. Keep it true.
agents/                       Rules, commands, knowledge base, skills
STEAL.md, .steal/manifest.md  What is safe to lift from here, and the index of it
biome.json, playwright.config.ts, promptfooconfig.yaml
                              The adopter's toolchain, shipped live. Inert here by
                                subject matter — runwAI has no JS/TS — never by design.
.runwai/                     runwAI's own record. Not the adopter's. Not in llms.txt.
.runwai/tools/               The self-checks. Deterministic, offline, no LLM. Maintainer
                                only — the template is not a Python project.
.runwai/decisions.yaml       Why the template is shaped this way. Structured, not ADRs.
report.md                     The self-check readout. Maintainer-facing, unlike
                                security-report.md beside it. Generated; never edit
```

## Verification discipline

This repository's history contains two classes of error, both of which look like competent
work until checked:

1. **Plausible-looking ISM control IDs that were never read.** Four mappings in the original
   draft were disproved by reading the authoritative text.
2. **Repository slugs asserted without resolution.** A 62-entry research inventory was
   deleted rather than verified; several entries turned out to be fabricated.

The pattern in both is the same: fluent output about something nobody checked. If you cannot
verify a claim, say so and mark it unverified. That is always the cheaper outcome.

Read the relevant record before changing anything that looks arbitrary — it probably is not.
The template's reasoning is in [`.runwai/decisions.yaml`](.runwai/decisions.yaml); this
project's configured state is in [`docs/setup.md`](docs/setup.md).

## Extended documentation

- **[agents/README.md](agents/README.md)** — index of rules, commands and skills
- **[agents/rules/](agents/rules/)** — modular engineering rules
- **[agents/running-the-checks.md](agents/running-the-checks.md)** — the canonical command list
- **[agents/knowledge-base.md](agents/knowledge-base.md)** — domain knowledge: ISM, gates,
  determinism
- **[docs/architecture.md](docs/architecture.md)** — the invariant in full
- **[.runwai/README.md](.runwai/README.md)** — the template's own record: backlog,
  decisions, provenance, pinning, contributing. **Only when working on runwAI itself**
