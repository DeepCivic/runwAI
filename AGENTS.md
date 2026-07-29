# runwAI — guide for AI agents

You are working in a **template repository for people building software with AI**. It maps
ISM controls to pinned, deterministic tools, ships the config files that enforce them, and
exists so that someone who is not a security engineer can understand what their code does
and does not satisfy.

**This file speaks to one reader: the agent building a product from this template.** If
your session is about maintaining runwAI itself — the prompt opens with `#maintainer`, or
says in as many words that the subject is the template rather than a product built from it
— this is not your guide: load [`.runwai/MAINTAINERS.md`](.runwai/MAINTAINERS.md) and work
from there. Absent that marker, you are building, and everything below applies.

One invariant outranks everything else here:

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

**2. Run the mechanical steps.** They are one command, and it is deterministic — every
tool pinned, every target the same command every time:

```bash
make first-session
```

That installs the pinned toolchain and the commit hook, runs every check once over the
whole tree, proves the rules catch the committed vulnerable examples
(`.github/scripts/verify.py` — the receipt they can hand to IT, whose failures come with
fixes), regenerates the report, then audits the dependencies and checks the environment.
The targets also run individually — `make check`, `make verify` — and each wraps exactly
one command from [`agents/running-the-checks.md`](agents/running-the-checks.md), the
canonical list.

`make audit` and `make doctor` run last and cannot abort the session: a dependency with a
CVE and an unset variable are both facts about the world rather than reasons to stop
setting up. The audit needs two networked setup steps first — `make setup-audit-tools`
and `make setup-audit-dbs` — and until they have run it will say so rather than report a
clean tree. Both are worth doing in the first session; the database is about a gigabyte,
so say that before running it.

The first full run may fail on files the template ships. Read the failure and fix or
explain it — do not tell them to re-run with `--no-verify`. Then relay `verify.py`'s
verdict in a sentence.

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

**4. Offer to delete `.runwai/`.** It is the template's own record — the maintainer guide,
backlog, decisions, provenance, pinning status — and it is about building runwAI, not about
building with it. Nothing in their project depends on it. **Do not read it in this mode, and
never cite it to the user:** runwAI's outstanding work is not their backlog and its
decisions are not theirs.

**If you delete it, prune what calls into it in the same commit** — the five hooks in
`.pre-commit-config.yaml` whose entry begins `python3 .runwai/tools/`, and the `selfcheck`
and `python-sast` jobs in `.github/workflows/posture.yml`. Those validate runwAI's own
structure, so removing them loses the user nothing, and the self-check readout
`.runwai/docs/report.md` goes with the directory itself. Leaving the hooks behind gives the
user a check that fails on a directory that is gone.

**5. Write down what you did** in [`docs/setup.md`](docs/setup.md). It is the *adopting
project's* record and it is as-built: what is configured right now, not what someone decided
once. Keep it true in the same commit that changes the setup.

**6. Make this file theirs.** `AGENTS.md` arrives describing runwAI — a template, and how
to set it up. The moment it is their repository that framing is wrong, and an agent opening
it next session will act on the wrong one. **Rewrite it in the same commit as the rest of
setup:**

- Replace the opening description with what *their* project is, in plain terms.
- **Delete the maintainer pointer at the top, and this first-session section itself** —
  the session has run, and if you deleted `.runwai/` the pointer links into a directory
  that is gone. A dangling link in the file every future agent reads first is exactly the
  confident-index failure this repository refuses.
- **Keep *Who you are working for*, *While you build*, and the guardrails pointer.** Those
  describe how to work with this person, not how to set up a template, and they are the
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
  checks. 36 of 1101 controls are mapped, most `partial`.
- **A check with nothing to look at is *not applicable*, not a pass.** Absent Terraform is
  not a finding and not a clean bill of health either. `make audit` names every ecosystem
  it did not scan, and `make doctor` says so outright when a project declares no
  environment requirements.
- **A clean codebase on a vulnerable dependency is not secure.** The report keeps
  **Dependency posture** separate from code findings for exactly that reason. Tell them
  what `make audit` found in the same breath as the rest.
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
- **If you bless a file with a `STEAL:` marker, add its row to `.steal/manifest.md` in the
  same commit** — the protocol is [`.steal/curation.md`](.steal/curation.md), and a
  self-check fails on a blessed file with no row.
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
here, because a command listed in four files is a command corrected in four files. The
root `Makefile` wraps the adopter-facing subset as targets and adds no command of its own.

Two layers, and they are not alternatives. `AGENTS.md` and `agents/` are the canonical,
vendor-neutral content. `.claude/commands/*.md` are thin Claude Code adapters pointing into
it — a slash command only works from that path, so it lives there and holds no content of
its own. If you add a command, point it at `agents/` rather than restating the instructions.

## Security guardrails for LLM-integrated code

Not loaded by default, because not every change needs it. Read
[`agents/knowledge/llm-security-guardrails.md`](agents/knowledge/llm-security-guardrails.md)
when you are writing code that calls a model, handles model output, or exposes a prompt
surface.

## Extended documentation

- **[agents/README.md](agents/README.md)** — index of rules, commands and skills
- **[agents/rules/](agents/rules/)** — modular engineering rules
- **[agents/running-the-checks.md](agents/running-the-checks.md)** — the canonical command list
- **[agents/knowledge-base.md](agents/knowledge-base.md)** — domain knowledge: ISM, gates,
  determinism
- **[docs/architecture.md](docs/architecture.md)** — the invariant in full
