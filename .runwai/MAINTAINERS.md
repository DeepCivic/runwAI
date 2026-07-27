# runwAI, from the maintainer's side

**Read this before changing anything structural.** `README.md` in this directory is an
index of what is here. This file is the argument: what runwAI is actually for, why it is
shaped the way it is, and which properties are load-bearing enough that a change should be
argued rather than made.

If you are building a project *from* this template, none of this is yours. Stop here and
read the root `AGENTS.md` instead.

## What this is for

The template gives an adopter two things, and they are not equally well understood:

1. **Practical scaffolding for AI coding.** `AGENTS.md`, the rules, the skills, and the
   toolchain configs live at the paths their tools already read. This is the part people
   get value from on day one.
2. **A mechanism for understanding a project's security posture.** A small set of pinned,
   deterministic checks, and a report that says what ran, what it found, and what nobody
   looked at.

**The second is a calibration instrument, not a security scanner.** The scanning is the
occasion. The product is a truthful answer to a question people habitually answer
dishonestly: *how much of a security baseline can a repository actually speak to?*

The numbers make the point. The baseline in use has 1101 controls; 694 are organisational —
people, policy, premises — and no repository can evidence them. Of the rest, a handful have
a check behind them here. Most tools in this space would render that as a percentage and a
green tick. This one is built, at every level, to refuse to.

That is why the scanning surface is deliberately small. Nine semgrep rules across two
rulesets is not a placeholder for a hundred; it is the amount that can be defended
honestly. Adding rules is easy and makes the product worse if the honesty layer does not
keep up with them.

**On the ISM specifically.** It was used as a *requirements baseline* while building this
template: a ready-made, published, citable list of what a security review asks about, which
saved inventing one and gave every mapping something authoritative to be checked against.
It is not the product, it is not a compliance offering, and an adopter needs no ISM
obligation for any of this to work. Keep it out of the adopter-facing positioning — the
root README mentions it once, where the report is explained, and once in the licence
attribution CC BY requires. That is the right amount. A reader who thinks they need to
understand the ISM to use the template has been lost by our writing, not by their own gap.

## The two invariants

**AI may perform the setup work. The controls themselves must be deterministic.** An LLM is
never in the decision path of a control. This is enforced in
`tools/validate_registry.py`, not by convention, and it is the precondition for everything
else: you cannot build an honesty machine on a component that gives different answers to
the same question.

**Never let a reader infer more coverage than exists.** This is the one that generates most
of the design. It shows up as a family of distinctions that the code spends more effort on
than it spends on detection:

| Not the same as | | Where it bites |
| :--- | :--- | :--- |
| `not applicable` | `pass` | A check with no subject matter found nothing, not nothing wrong |
| `unassessed` | `reachable` | ISM-0260 needs a web proxy. Its surface is not organisational, and no repository declares it |
| a check being wired | a check having run | A check that has not fired this commit is not evidence |
| a check running | a check preventing something | The workflow was green for its whole life and stopped nothing. See decision 6 |
| no scanner output | nothing found | A missing findings file must read differently from a clean scan |
| `mapped` | `enforced` | A control with no `implementation` block has nothing running |
| `inert` | `absent` | Content nobody knows to copy is invisible to its reader and looks like coverage to everyone else |
| a surface | something we can reach | Where the evidence lives, not whether we can get to it |

Four times now the honest answer has cost apparent coverage, and each time the smaller true
number won: an `automatable_count` of 754 deleted from the index, "checked here" demoted to
"has a check behind it", the empty-findings section split into "no scanner ran" versus "the
scanner ran and found nothing", and a blocking PR gate deleted once it was established that
nothing required it to pass. **If a change makes one of those numbers go up without more
actually being checked, it is a regression.**

The fourth is the instructive one, because it survived longest. It was in the workflow
header, in the README, in the architecture doc, and in the registry as `blocking: true` on
twenty-three controls — and it was false in all four places for the same reason: nobody had
checked whether the repository had branch protection. It did not. Fluent, consistent,
cross-referenced, and wrong, which is precisely the failure mode
[`status.md`](status.md) records under verification discipline. Consistency across four
documents is not evidence; it usually means one unchecked claim was copied three times.

## Who it is for, and why that shapes the code

The user is building a product, is capable, and is not a security engineer. The design
constraint that follows is sharper than it sounds:

> They do not know what to ask for, so the knowledge cannot live where a question would
> reach it.

That is why obligations live in `AGENTS.md`, which an agent reads unprompted, rather than
in documentation a person has to find. Most repositories put instructions where the human
looks. This one assumes the human never looks, and that assumption is why the template
works at all. A feature that depends on the user knowing to ask for it is a defect here.

## The shape, and what is load-bearing

| Piece | What it does | Load-bearing? |
| :--- | :--- | :--- |
| `controls/ism-*` | The baseline, tagged by whether a repository can evidence a control | **Yes.** Everything downstream reads it |
| `controls/registry.yaml` | Control → mechanism → tool → `implementation` | **Yes.** The report's honesty depends on `implementation` being verified, not claimed |
| `controls/rules/`, `controls/tests/` | The nine rules and their fixtures | The rules are replaceable. The both-directions assertion is not |
| `.github/scripts/security_report.py` | The artefact the whole thing exists to produce | **Yes** |
| `.pre-commit-config.yaml` | The only check here that stops anything | **Yes**, and it is the whole of the enforcement story |
| `.github/workflows/posture.yml` | The only workflow. Reports; blocks nothing | Yes as the report's home; not as enforcement |
| `AGENTS.md`, `agents/` | Where the unprompted knowledge lives | **Yes** |
| `.runwai/` | This record | No. Deletable by design |

The ISM is the first instance of a method, not the method itself. Tag a baseline by whether
a repository can evidence each control, run a small deterministic set, report the gap
honestly — that works identically against NIST 800-53 or the Essential Eight.
`controls/ism-tags.yaml` is a worked example. Nothing prevents a second one, and nothing in
the adopter-facing layer should read as though the ISM were the point.

## What we have already decided, and should not relitigate casually

Each of these is argued in full in [`decisions.yaml`](decisions.yaml). Summarised so you
know when you are about to overturn one.

1. **Vendor only permissive, licence-verified content** — share-alike obligations
   propagate to every adopter. This is why the rules are original: the obvious upstream
   ruleset ships under a bespoke licence, recorded in `backlog.yaml` as TODO-16.
2. **Everything ships live, at the path its tool reads.** No directory of files awaiting a
   copy step. The one extension: a config the project does not need should be *deleted*,
   and the checks treat a complete deletion as a pass.
3. **`.runwai/` owes the template's conventions nothing.** Its readers are a maintainer
   and an agent. Structured data where the content is enumerable, prose where it is
   argument.
4. **One canonical agent layer, thin vendor adapters.** `agents/` holds the content;
   `.claude/commands/` holds pointers and nothing else.
5. **A control carries its own implementation.** There is no capability layer, and the
   scaffolding for a library nobody has yet is the same error as a directory of files
   nobody copies.
6. **runwAI ships no merge gate and describes none.** Preventing a merge is branch
   protection — a repository setting at the forge, not a file a template can carry — so
   claiming one is claiming to install something we structurally cannot. `mechanism` takes
   `pre-commit` or `posture` and nothing else, and `validate_registry.py` rejects
   `blocking: true` on anything routed to `posture`. **Do not reintroduce a gate-shaped
   workflow.** If enforcement is wanted, the honest deliverable is documentation telling an
   adopter which branch-protection settings to switch on — not a workflow that looks like
   the answer.

## How to tell a good change from a bad one

**Good:** the report says something truer than it did before. A distinction gets sharper. A
claim gains a receipt. Something inert becomes either live or deleted.

**Bad:** a number goes up without more being checked. A check is added faster than the
honesty layer can describe it. A gate is moved after it went red — as distinct from being
placed deliberately in advance, which is design. Scaffolding appears for a scale the
product does not have.

**The test to apply:** if a stranger read the generated report and formed a belief about
this project's security, would that belief be true? Everything here exists to make the
answer yes.

## Where to go next

- [`backlog.yaml`](backlog.yaml) — outstanding work in rank order, plus `before_release`,
  the shorter list a release decision turns on
- [`decisions.yaml`](decisions.yaml) — why the template is shaped this way, argued
- [`contributing.md`](contributing.md) — how to add a check
- [`status.md`](status.md) — what is present and what is honestly known about its limits
- [`pinning.md`](pinning.md) — verified pins, pending pins
- [`provenance.md`](provenance.md) — upstream, SHA and licence for every derived file
