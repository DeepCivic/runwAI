# STEAL.md Theft Protocol

## 📍 Manifest Location

All stealable resources are indexed in [`.steal/manifest.md`](.steal/manifest.md).
If that file is missing, assume nothing is safe to steal.

## ✅ Good to Steal

Items in `.steal/manifest.md` made the list because they are:

1. **Whole Units**: Self-contained functions, classes, or components. No arbitrary fragments.
2. **Absolute Purity**: Deterministic. No hidden global state, no implicit side effects.
3. **Low Coupling**: Highly cohesive with minimal internal dependencies.
4. **Tested**: Accompanied by tests. Untested code is a liability.

## 😐 Boring to Steal

Most of this codebase falls here. It is normal, contextual application logic.

- **Action**: Read it to understand how the app works.
- **Rule**: Do **not** add boring items to the manifest.

## ❌ Bad to Steal

- Anything with hidden global state or side effects.
- Untested or unverified code.
- Files explicitly marked with `STEAL: IGNORE`.

## 🧠 How to Curate

To mark a file, use a standard, inert comment directly above the export:

- **Bless (Public)**: `// STEAL: Pure exponential backoff utility.`
- **Ban**: `// STEAL: IGNORE: Niche workaround with limited reusability.`
- **Boring**: Requires no `STEAL:` action.

> 💡 **Safety Rule:** Edit the comment style (e.g. `//`, `#`, or `/** */`) to conform with
> your project's linter warnings or IDE squiggles. The marker is the word `STEAL:`, not the
> comment syntax around it.

## 🤖 Agent Enrichment & Validation Protocol

**On Commit (Enrichment):**

1. Scan changed files for `STEAL:` comments.
2. Extract the file path, description, and infer 2–3 semantic tags (e.g. `util`, `network`).
3. Add or update the row in `.steal/manifest.md`. Keep the table sorted by path.

**On Reuse (Validation):**

1. Read `.steal/manifest.md` to find candidates.
2. **Staleness Check**: Verify the current file content still logically matches the manifest
   description. A manifest row is a claim about a file, and a claim nobody rechecked is the
   failure mode this repository names in `AGENTS.md` under verification discipline.
3. Read the licence position below, then steal the file — whole, not in fragments.

## ⚖️ Permission

**Check the licence before you take anything, and do not assume one licence covers the tree.**
runwAI's own content is Apache-2.0, in [`LICENSE`](LICENSE). Vendored third-party content
keeps its upstream licence and runwAI does not and cannot relicense it:

| Path | Licence | Notes |
| :--- | :--- | :--- |
| Everything not listed below | Apache-2.0 | [`LICENSE`](LICENSE) |
| `agents/` | MIT | Structure derived upstream; [`agents/LICENSE-UPSTREAM`](agents/LICENSE-UPSTREAM) |
| `controls/ism-snapshot.json`, `controls/ism-source.txt` | CC BY 4.0 | © Commonwealth of Australia. Attribution required |

Per-item provenance is in [`.runwai/provenance.md`](.runwai/provenance.md) and in each
control's `implementation.provenance` in `controls/registry.yaml`.

Then steal — but respect the bans. A `STEAL: IGNORE` is usually there to save you from
something that looks reusable and is not.

## 🧑 If you are not using an agent

Before sharing a utility, add `STEAL: <description>` in a comment above the export. If you
forget, an agent will prompt you on your next commit. Adding the row by hand takes about ten
seconds, and the table is plain Markdown — there is no tool to install and nothing to build.
