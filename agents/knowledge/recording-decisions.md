# Recording decisions

Load this during the first session, when the user has to choose how their project keeps its
decisions, and again whenever a decision is worth writing down. A decision log is the
answer to "why is it like this?" six months on, asked by someone who was not in the room —
usually the next agent session.

## The choice

Two shapes work. Neither is better in general; they suit different projects.

| | Decisions file | ADRs |
| :--- | :--- | :--- |
| Where | `docs/decisions.yaml`, one file | `docs/adr/0001-short-title.md`, one file each |
| Read by | An agent, a maintainer, a search | People browsing, reviewers reading a pull request |
| Strength | One place to look, queryable fields, almost no ceremony | Each decision is its own reviewable, linkable page |
| Cost | A long file gets heavy, and edits to old records show up in one shared diff | Many small files, an index to keep, a numbering convention to hold |
| Suits | One person or a small team, most work done through an agent | Several people who review each other's changes, or readers outside the team who expect ADRs |

Put the choice to the user as a question about their situation, not a format preference:

1. Will more than one person review changes to this project?
2. Will anyone outside the team need to read why things are the way they are — a client, an
   auditor, an open-source contributor?
3. Do you expect more than a few dozen decisions?

Two or three "yes" answers favour ADRs. Otherwise, or if they are unsure, **recommend the
decisions file**: it costs less to keep up, and moving to ADRs later is a mechanical
conversion of each record into a file. Say which you would take and why, then do what they
choose. Record the choice in `docs/setup.md`.

Keep exactly one. Two logs is two sources of truth for the same question.

## What counts as a decision

Write one when the choice was between real alternatives and the reason would not be obvious
from the code: a library over another, a data store, an authentication approach, a check
turned off or a config deleted on purpose. Do not write one for choices that follow the
convention of the stack, and do not record a decision the user has not actually made.

**Say in plain language when a decision touches authentication, secrets, user data, network
exposure or a dependency**, as `AGENTS.md` requires of every change. The log records it; it
does not replace telling the user.

## Records are history

A record describes what was true when it was written. When a later decision changes an
earlier one, add the new record and mark the old one `superseded` (or note what it
`amends`); never rewrite the old argument to match the present. Ids are stable and never
reused or renumbered.

## The decisions file

Create it at setup, with only the header, so the first real record is number 1.

```yaml
# Why this project is the way it is. One record per decision; newest last.
# id: stable, never reused    status: accepted | superseded | withdrawn
version: 1
decisions:
  - id: 1
    title: One line, naming the choice
    status: accepted
    date: "YYYY-MM-DD"
    context: What forced a choice, and what was on the table
    decision: What was chosen, and the reason
    consequences: What gets easier, what gets harder
    alternatives_considered:
      - What else was weighed, and why it lost
```

## ADRs

Create `docs/adr/` at setup with a short `README.md` saying the numbering convention. One
file per decision, named `NNNN-short-title.md`, numbered from 0001, never renumbered:

```markdown
# 0001. Title naming the choice

Status: accepted · Date: YYYY-MM-DD

## Context
## Decision
## Consequences
```

The layout follows the convention `backstage/backstage` uses for its ADRs (structure only,
recorded in `.runwai/docs/provenance.md`); the text is ours.
