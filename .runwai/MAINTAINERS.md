# runwAI Maintainer Guide (Concise)

## Purpose
runwAI delivers two value streams:
- **AI coding scaffolding**: AGENTS.md and live toolchain configs at expected paths
- **Honest security posture reporting**: Small set of deterministic checks with transparent coverage reporting

The security report is a calibration instrument - its value is truthfulness about actual coverage, not scan results.

## Core Principles
1. **Determinism**: No AI in security decision path - same input = same output
2. **Honest coverage**: Never imply more coverage than exists (9 rules, not 100+)
3. **"You shouldn't need to know what to ask for"**: Critical knowledge lives in AGENTS.md for agents to read unprompted

## Load-Bearing Components
| Component | Critical? | Why |
|-----------|-----------|-----|
| controls/registry.yaml | Yes | Report honesty depends on verified implementation |
| security_report.py | Yes | Primary output artifact |
| .pre-commit-config.yaml | Yes | Only enforcement mechanism |
| AGENTS.md/agents/ | Yes | Unprompted knowledge delivery |
| ISM baseline | No | Method works with any framework |

## Key Decisions
- No merge gates (honest about limitations - enforcement is branch protection)
- Files ship live at correct paths (no copy steps)
- Vendor only permissive content (no share-alike obligations)
- Small honest coverage > broad misleading coverage

## Change Evaluation
A change is good if:
- Makes the report more truthful
- Sharpens distinctions in coverage reporting
- Adds verifiable receipts for claims

A change is bad if:
- Inflates coverage numbers without actual checks
- Adds checks faster than honesty layer can describe them
- Introduces gate-shaped workflows that can't be enforced

## ALWAYS
- Update AGENTS.md in root if appropriate; audience is the template-users agent
- Update README.md in root if appropriate; audience is the template-user
- Keep root .md files concise

The test: Would a stranger form an accurate belief about security posture from the report? Everything exists to make the answer "yes."