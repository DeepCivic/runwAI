---
title: Assert every rule in both directions
impact: HIGH
impactDescription: The passing case matters more than the failing one
tags: testing, selftest, semgrep
---

## Assert every rule in both directions

**Impact: HIGH**

Every rule needs a fixture that makes it fire and a fixture that must leave it silent.
Semgrep pairs fixtures to rule files by basename, so `files/injection.yaml` requires
`selftest/injection.py`.

The `ok:` cases matter more than the `ruleid:` ones. Any rule can be made to fire — a rule
matching everything fires perfectly. What distinguishes a control from noise is that it
stays quiet on correct code. A rule that flags `cur.execute("SELECT 1")` teaches developers
to ignore the scanner, and an ignored scanner reports green while enforcing nothing.

**Incorrect (only the failing case is asserted):**

```python
# ruleid: runwai-python-sql-string-building
cur.execute(f"SELECT * FROM users WHERE id = {user_id}")
```

**Correct:**

```python
# ruleid: runwai-python-sql-string-building
cur.execute(f"SELECT * FROM users WHERE id = {user_id}")

# ok: runwai-python-sql-string-building
cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
```

Run it:

```bash
semgrep --test --config controls/rules controls/tests
```

Enforced by: the `ruleset-tests` job in `.github/workflows/posture.yml`. It is the only
place the rules themselves are tested — everything else runs them *against* code.

Reference: [.runwai/contributing.md](../../.runwai/contributing.md)
