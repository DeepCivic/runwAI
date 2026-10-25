# Security guardrails for LLM-integrated code

Load this when writing code that calls a model, consumes model output, or exposes a prompt
surface. It is deliberately **not** part of `AGENTS.md` — most changes in most repositories
do not touch a model, and always-loaded context costs tokens on every request.

## On sourcing

The category identifiers below (LLM01–LLM10) come from the OWASP GenAI LLM Top 10 2026.
That project is licensed **CC BY-SA 4.0**, which is share-alike:
copying its prose would place a copyleft obligation on this file and on every repository
that adopts this template. So the identifiers and the link are OWASP's; every sentence here
is ours.

Source: <https://genai.owasp.org/resource/owasp-genai-llm-top-10-2026/>

The numbering changed between editions, so an identifier cited from an older list (the
2023 and 2025 lists differ from this one) points at a different category here.

## The guardrails

### LLM01 — Prompt injection

**Do not concatenate untrusted input into a system prompt.** Anything a user, a web page, a
file, a tool result or an upstream API supplied is untrusted, including content that arrived
indirectly — a model summarising a fetched document is reading attacker-controlled text.

Keep instructions and data in separate turns or fields. Treat any instruction that arrives
inside data as data.

### LLM02 — Sensitive information disclosure

Do not place secrets, credentials or personal data in prompts. Prompts are frequently
logged, cached and retained by providers. Assume anything sent is recorded, and anything
the model has seen can come back out.

### LLM03 — Excessive agency

Give a model the narrowest tool surface that works, and separate proposing an action from
performing it. A tool that takes a free-text command and runs it has delegated arbitrary
execution to a probabilistic system. Prefer typed parameters over strings, enforce
authorisation in the tool rather than in the prompt, and put anything destructive,
outward-facing or expensive behind a deterministic check or a human.

### LLM04 — Supply chain

Pin model identifiers, SDK versions and prompt templates. An unpinned model identifier is
the same defect as an unpinned scanner: behaviour changes under you without a diff. Pin and
checksum third-party weights too — loading a pickled model executes code, which is why this
repository's `controls/rules/deserialisation.yaml` exists.

### LLM05 — Data and model poisoning

If a pipeline ingests third-party or user-supplied data for training, fine-tuning or
retrieval, record where it came from and check it before it is used. Poisoned inputs
change behaviour without changing any code, so a diff will not show them.

### LLM06 — Unbounded consumption

Unbounded prompts, unbounded output length and unbounded retries are an availability
problem and a billing one. Set explicit limits and time-outs. If you host weights, treat
them as the asset they are: access control, egress limits and audit logging, because
unrestricted query access is also how a model gets copied.

### LLM07 — Misinformation

**Do not rely on a model for a security decision.** This is the repository's core invariant
restated: a model may advise, it may never adjudicate. "Ask the model whether this is safe"
is not a control, because the same input can produce different verdicts, and a fluent
answer is not a checked one.

### LLM08 — Hidden context exposure

Assume a user can extract anything placed in a system prompt, tool description or hidden
context. Keep secrets, access rules and anything whose disclosure helps an attacker out of
it; enforce those in code.

### LLM09 — Vector and embedding weaknesses

Where similarity search decides what the model sees, the embedding store is part of your
trust boundary. Apply access control at retrieval, per user, not only at ingestion, and
treat retrieved text as untrusted input (LLM01).

### LLM10 — Improper output handling

**Treat model output as untrusted input to whatever consumes it.** Output flowing into a
shell, SQL statement, `eval`, file path, HTML sink or HTTP request is an injection vector
with an extra step. The fact that a model produced the string grants it no privilege.

Validate and encode at the boundary exactly as you would for user input.

## The three that matter most here

Compressed for the common case:

1. **Never pass raw user input into a system prompt.** Instructions and data stay separate.
2. **Never execute model-generated code or shell commands without strict sandboxing.**
   Generated code is a proposal, not an instruction.
3. **Never rely on a model for a security decision.** Enforcement is a pinned tool
   returning an exit code.

## What this file is not

Guidance for humans and agents writing code. It is **not** a control: nothing here is
mechanically enforced, and reading it produces no evidence of anything. Where a guardrail
can be enforced deterministically, it belongs in a ruleset under `controls/rules/` with a
ruleset and fixtures — not in prose.

Related: [controls-never-adjudicate-with-llm](../rules/controls-never-adjudicate-with-llm.md)
