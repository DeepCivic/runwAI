# runwAI — guide for AI agents

You are working in a **template repository for people building software with AI**. It maps
ISM controls to pinned, deterministic tools, ships the config files that enforce them, and
exists so that someone who is not a security engineer can understand what their code does
and does not satisfy.

## Scope

**This file governs every session in this repository, at every path**, and it speaks to one
reader: the agent building a product from this template. If your session is about
maintaining runwAI itself — the prompt opens with `#maintainer`, or says in as many words
that the subject is the template rather than a product built from it — this is not your
guide: load [`.runwai/MAINTAINERS.md`](.runwai/MAINTAINERS.md) and work from there. Absent
that marker, you are building, and everything below applies.

There are deliberately no nested `AGENTS.md` files: a second one is a second thing to rewrite
when this repository becomes someone's product. Adding one is a decision, not a convenience.

## The one invariant

> **AI may perform the setup work. The controls themselves must be deterministic.**

**Deterministic means: same input, same output, every time. No model, no network, no
clock.** You may write controls, rules, configs, workflows and docs freely. You may **never**
put a model in the decision path of a control. A check may be *authored* by an agent; it may
not be *adjudicated* by one. `.runwai/tools/validate_registry.py` enforces this mechanically
and will fail the build if you violate it — so this is a rule you cannot talk your way past.

Writing a *new* rule is ordinary work. **Changing an existing one is a claim about what it
catches**, so run `make verify` before and after and show that the fixture assertions still
hold in both directions.

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

**2. Run the mechanical steps.** They are one command, and it is deterministic — every
tool pinned, every target the same command every time:

```bash
make first-session
```

That installs the pinned toolchain and the commit hook, runs every check once over the
whole tree, proves the rules catch the committed vulnerable examples
(`.github/scripts/verify.py` — the receipt they can hand to IT, whose failures come with
fixes), regenerates the report, then audits the dependencies and checks the environment.

`make audit` and `make doctor` run last and cannot abort the session: a dependency with a
CVE and an unset variable are facts about the world, not reasons to stop setting up. The
audit needs `make setup-audit-tools` and `make setup-audit-dbs` first, and until they have
run it says so rather than reporting a clean tree. Both are worth doing now — the database
is about a gigabyte, so say that before running it.

The first full run may fail on files the template ships. Read the failure and fix or
explain it — never tell them to re-run with `--no-verify`. Then relay `verify.py`'s verdict
in a sentence.

**3. Work out which of the three root configs they actually need.** Read the table, then
ask what they are building — in that order, so you arrive with the question already framed
rather than deciding after the fact. They will not know these are theirs to delete.

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

**4. Offer to delete `.runwai/`.** It is the template's own record — the maintainer guide,
backlog, decisions, provenance, pinning status, and the social preview card for a
repository that is no longer this one — and it is about building runwAI, not about building
with it. Nothing in their project depends on it. **Do not read it in this mode, and never
cite it to the user:** runwAI's outstanding work is not their backlog and its decisions are
not theirs.

**If you delete it, prune what calls into it in the same commit** — the five hooks in
`.pre-commit-config.yaml` whose entry begins `python3 .runwai/tools/`, and the `selfcheck`
and `python-sast` jobs in `.github/workflows/posture.yml`. Those validate runwAI's own
structure, so removing them loses the user nothing, and the self-check readout
`.runwai/docs/report.md` goes with the directory itself. Leaving the hooks behind gives the
user a check that fails on a directory that is gone.

**5. Ask about the reuse layer — [`STEAL.md`](STEAL.md) and
[`.steal/`](.steal/curation.md) — and do not decide it for them.** Unlike `.runwai/`, this
one is not obviously nobody's: it is a working protocol for publishing units of code other
people can lift, and whether that matters depends entirely on something you cannot infer
from the tree. **Ask which of these they are**, in their terms — *"do you want other people
to be able to reuse pieces of this?"*:

| They say | Do this |
| :--- | :--- |
| Yes, or open source | **Keep both.** The five rows in `.steal/manifest.md` describe files they inherited, so the index is true on day one. Tell them it becomes theirs to curate: bless a file with a `STEAL:` comment and the row goes in the same commit |
| No, it is private | **Delete `STEAL.md` and `.steal/` together, in one commit**, plus their three entries in `llms.txt`. Then run `make check` and clear every link it names — the link check is the list, so do not work from memory. Both gone is a decision and one gone is an error, so a half-deletion reports itself |
| Not sure | **Keep it.** It is inert until someone writes a `STEAL:` comment, it blocks nothing, and deleting it later is one commit. Say that, rather than pressing for an answer |

The failure to avoid is deleting it silently because it looks like template furniture. It
is the one part of this repository whose value is a fact about *their* intentions.

**6. Write down what you did** in [`docs/setup.md`](docs/setup.md). It is the *adopting
project's* record and it is as-built: what is configured right now, not what someone decided
once. Keep it true in the same commit that changes the setup.

**7. Make this file theirs.** `AGENTS.md` arrives describing runwAI — a template, and how
to set it up. The moment it is their repository that framing is wrong, and an agent opening
it next session will act on the wrong one. **Rewrite it in the same commit as the rest of
setup:**

- Replace the opening description with what *their* project is, in plain terms.
- **Delete the maintainer pointer, and this first-session section itself** — the session has
  run, and if you deleted `.runwai/` the pointer links into a directory that is gone. A
  dangling link in the file every future agent reads first is exactly the confident-index
  failure this repository refuses.
- **These sections are not template-specific and must survive the rewrite:** *Who you are
  working for*, *The one invariant*, *While you build*, *Don't touch*, and the guardrails
  pointer. They describe how to work with this person and what not to break, not how to set
  up a template, and they are the reason the file is worth keeping at all. **If you are
  unsure whether a section should stay, keep it** — an extra paragraph costs context, and a
  deleted obligation costs the user something they cannot see is missing.
- **Add what an agent cannot infer about their project**: how to run it, where the tests
  are, what it must never touch, which commands are safe unprompted.
- **Leave [`CLAUDE.md`](CLAUDE.md) as the one-line import it is** — see *Two layers* below.

Then tell them you have done it, in one line. They will not know this file governs every
later session, and it is the file most likely to rot silently — the cost of leaving it
describing a template lands on a future session, not this one.

**8. Tell them these things unprompted**, because each is something they would otherwise
discover at the worst moment:

- **Nothing here can prevent a merge.** The commit hook is the only thing that stops an
  action, and `git commit --no-verify` walks straight past it. CI reports. Blocking a merge
  is branch protection — a setting at their forge that no template can switch on for them.
- **A green report is not compliance.** It means their code did not trip a set of automated
  checks. 36 of 1101 controls are mapped, most `partial`. Say the numbers: an unquantified
  "limited coverage" is the vague claim the number exists to replace.
- **A check with nothing to look at is *not applicable*, not a pass.** Absent Terraform is
  not a finding and not a clean bill of health either. `make audit` names every ecosystem
  it did not scan, and `make doctor` says so outright when a project declares no
  environment requirements.
- **A clean codebase on a vulnerable dependency is not secure.** The report keeps
  **Dependency posture** separate from code findings for exactly that reason. Tell them
  what `make audit` found in the same breath as the rest.
- **They can ignore the control identifiers entirely** and the report still tells them what
  is checked and what is not.

## The commands

Every command lives in [`agents/running-the-checks.md`](agents/running-the-checks.md) with
its flags, its exit codes and what it covers. **That file is canonical and this section is
an index** — a command listed in four files is a command corrected in four files, so nothing
here restates a flag. Read it when you need to run anything not in this table.

| Target | What it does | Needs the network? |
| :--- | :--- | :--- |
| `make first-session` | All of the below, in order | Yes, via `setup` |
| `make setup` | Install the pinned toolchain | Yes — the only one that does |
| `make hook` | Install the commit hook | No |
| `make check` | Every commit-time check, over the whole tree | No |
| `make verify` | Prove the rules catch their committed examples | No |
| `make audit` | Scan dependencies, write the bill of materials | No, after its two setup targets |
| `make doctor` | Compare the declared environment to the real one | No |
| `make report` | Regenerate `docs/security-report.md` | No |

The `Makefile` wraps that page and adds no command of its own. **`make check` is the whole
suite — there is no `make test` and no `make lint`**, and guessing at one is how a session
ends up reporting a target it never ran.

**Tests.** The rule fixtures are in [`controls/tests/`](controls/tests/), a floor of three
vulnerable and one safe case per rule so an untested rule cannot pass silently, and
`make verify` runs every rule against them in both directions, twice, requiring identical
verdicts. **A rule never asserted silent on the good case is half-tested**, and it is the
half that produces false positives. The single-ruleset invocation is on the canonical page.

**No `biome` or `playwright` run exists here to copy** — runwAI is Python, YAML and Markdown.
If the user keeps one of those configs, run it the way their project does, at the version
`README.md` documents.

## While you build

Once setup is done, most of this repository is scaffolding for their product and should stay
out of the way. What still holds:

**Always**

- Put a new check where it can actually see the problem. Commit time is for what must never
  enter history — a leaked credential — and is the only place anything stops here. Anything
  structural, or needing the whole tree or full history, goes in
  `.github/workflows/posture.yml`, which reports.
- Pin every tool to an exact version. Never a floating specifier: `latest`, `*`, `^`, `~`,
  or a bare major tag.
- Report `not applicable` distinctly from a pass. **Never fail a project for lacking
  subject matter it was never going to have.**
- Add a `STEAL:` marker's row to `.steal/manifest.md` in the same commit — the protocol is
  [`.steal/curation.md`](.steal/curation.md), and a self-check fails on a blessed file with
  no row. Skip this if the reuse layer was removed in step 5.
- Use `rg` (ripgrep) for searching in preference to `grep`, and write comments that explain
  **why**, not **what**.
- Prefer stating "I could not verify this" over producing a confident guess.

**Ask first**

- Before a **large** change — and large means concretely: adding a dependency, changing what
  an existing control enforces, editing the `Makefile` or `.pre-commit-config.yaml`, or
  touching more than about three files outside the one you were asked to change. Phrase the
  question so someone non-technical can answer it, in terms of what they want their product
  to do rather than which tool or schema field to use.
- Before adding a setup step the user has to run. That is the one-step obligation above, and
  the answer is usually a different design.
- Before deleting anything the user has not named. Steps 3, 4 and 5 are the exception,
  because each is an explicit ask.

**Never**

- Put a model in the decision path of a control. No `llm-judge`, `ai-review` or
  `model-adjudication` tool class; the validator rejects them by name.
- Weaken a check to make CI green. Fix the finding, or state plainly that you could not.
  Deciding *in advance* where a check runs is design; *moving* one after it fails is
  weakening it.
- Describe anything here as blocking a merge. Nothing does, and claiming otherwise is the
  coverage lie this repository is built to refuse.
- Require the user to understand the ISM, or runwAI's vocabulary, to get a useful answer.
- Commit secrets, API keys or `.env` files.
- Route around a gate you do not understand. Report the failure instead.

## Don't touch

Generated files and vendored text. Editing either produces a file that looks authoritative
and is not — and in the vendored case, one whose upstream licence no longer describes it.

| Path | Why | Instead |
| :--- | :--- | :--- |
| `docs/security-report.md` | Generated | `make report` |
| `docs/dependencies.md` | Generated, and timestamp-free so a diff means the dependency set changed | `make audit` |
| `controls/ism-index.json` | Generated join of the snapshot and the tags | Edit `controls/ism-tags.yaml`, then regenerate |
| `controls/ism-snapshot.json` | Australian Government ISM text, CC BY 4.0. Not runwAI's to alter | Nothing. Quote it verbatim or not at all |
| `agents/LICENSE-UPSTREAM` | The licence the `agents/` layout was derived under | Nothing |
| `controls/tests/` | Working vulnerabilities, written so each rule can be asserted against them | Add a fixture pair; never "fix" one |
| `.runwai/` | The template's own record, not this project's | Offer to delete it whole (step 4). Do not cite it to the user |
| `LICENSE` | Apache-2.0, and the reason the helper layer is takeable | Nothing, until the project's own licensing changes |

`controls/tests/` is also excluded from every normal scan in `.semgrepignore`. If a scan
starts reporting findings there, the exclusion broke — that is the bug, not the findings.

## Two layers, and the adapters

`AGENTS.md` and `agents/` are the canonical, vendor-neutral content. Everything else pointing
at them holds no content of its own, and must not start to: `.claude/commands/*.md` are thin
Claude Code slash commands, which only work from that path, and [`CLAUDE.md`](CLAUDE.md) is a
one-line import, because Claude Code reads that filename and not this one. **Delete the
bridge and every instruction here becomes invisible to Claude Code; paste this file into it
and there are two guides to keep in step.** Claude-specific additions go below the import,
and a new command points at `agents/` rather than restating it.

## Security guardrails for LLM-integrated code

Not loaded by default, because not every change needs it. Read
[`agents/knowledge/llm-security-guardrails.md`](agents/knowledge/llm-security-guardrails.md)
when you are writing code that calls a model, handles model output, or exposes a prompt
surface.

## Extended documentation

- **[README.md](README.md)** — the human's front door, including the full directory map and
  the same first session written as a checklist they can hold you to
- **[agents/README.md](agents/README.md)** — index of rules, commands and skills
- **[agents/rules/](agents/rules/)** — modular engineering rules
- **[agents/running-the-checks.md](agents/running-the-checks.md)** — the canonical command list
- **[agents/knowledge-base.md](agents/knowledge-base.md)** — domain knowledge: ISM, gates,
  determinism
- **[docs/architecture.md](docs/architecture.md)** — the invariant in full
