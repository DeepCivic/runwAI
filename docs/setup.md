# How this project is set up

**This file is as-built, not a proposal.** It describes what is actually configured in this
repository right now — what runs, what was removed, and why. When you change the setup,
change this file in the same commit so it stays true. It is the first thing an agent should
read after `AGENTS.md` when it needs to know what it is working inside.

It arrives describing runwAI as it ships. Everything below is accurate on day one and
becomes yours as your agent adapts it.

## What runs, and when

| When | What happens | Does it stop you? |
| :--- | :--- | :--- |
| While you build | Nothing | No |
| On commit | Secret scan and SAST on what you staged, plus structural self-checks | Yes — this is the only place anything stops |
| On push and pull request | The same checks again, plus `security-report.md` | No, never |

**Nothing here prevents a merge.** The commit hook is the only thing that stops an action,
and `git commit --no-verify` walks past it. CI reports. If you want a failing check to
actually block a merge, switch on branch protection for this repository and require the
`posture` jobs — that is a setting at your forge, and no template can turn it on for you.

The last row is the point of the repository. It answers "how does what I have built compare
to a security baseline?" and it blocks nothing, so it is safe to ignore until you want it.

## What checks your code

| Control | Mechanism | Covers |
| :--- | :--- | :--- |
| RWA-0010 | `detect-secrets`, pinned, at commit time | Credentials before they enter history |
| RWA-0010 | `keyhog` 0.5.47, pinned, in CI | The whole tree and its reachable history, with far more detectors |
| RWA-0003, RWA-0020, RWA-0021 | `controls/rules/injection.yaml` | SQL, shell and HTML sink injection |
| RWA-0022, RWA-0074 | `controls/rules/deserialisation.yaml` | pickle, marshal, unsafe YAML, `eval`, pickled model loading |

Ten rules. That is the whole of it, and it is deliberate — a first release defends a small
surface honestly rather than a large one badly. Every other control in
`controls/registry.yaml` is mapped with nothing running, and `security-report.md` says so
in those words.

None of it is taken on trust: `python3 .github/scripts/verify.py` proves each rule catches
its committed vulnerable examples and stays silent on the safe ones, and CI re-proves it on
every push. See `agents/running-the-checks.md`.

## The toolchain configs, and deleting the ones you do not need

Three configs ship at the root. They do three unrelated jobs, and **most projects need
fewer than three.** Deleting one you will not use is the correct action, not a compromise —
a config nobody runs is a file that rots and misleads the next reader.

| File | Job | Delete it when |
| :--- | :--- | :--- |
| `biome.json` | Formatting and linting for JavaScript and TypeScript | There is no JS/TS here, or you use a different formatter |
| `playwright.config.ts` | Browser and end-to-end tests | There is no browser UI to test |
| `promptfooconfig.yaml` | Deterministic evals for prompts and agent tools | Nothing here calls a language model |

Deleting one is three edits in the same commit: the file, its row in `README.md`'s
toolchain table, and its entry in `llms.txt`. A self-check fails on any left behind, so you
will be told rather than left with a dangling reference. Record the removal below.

## What was removed from the template

Nothing yet. Record deletions here as your agent makes them, with a line saying why, so a
later reader does not spend an afternoon looking for a directory that was removed on
purpose.

## What this repository cannot tell you

The ISM governs a system: the people who run it, where it is hosted, who is allowed near
it. This repository sees code and a pipeline. Of 1101 controls, 694 are organisational and
no repository can evidence them. A green build here is not compliance and must never be
described as such.
