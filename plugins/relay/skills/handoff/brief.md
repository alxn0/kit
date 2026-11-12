# Handoff brief format

Shared by `handoff` (writes it) and `inbox` (reads it). One file per handoff, named
`<YYYY-MM-DD>-<slug>.md`, slug in lowercase kebab-case (`2026-11-08-kit-todo`).

The receiver has none of the sender's context: the brief must stand alone.

```markdown
---
from: <sender hostname>
date: <YYYY-MM-DD>
project: <optional: path of the project on the receiver, e.g. ~/GitHub/owner/repo>
---
# <Title: the work, imperative>

## Goal
One or two sentences: the outcome, not the steps.

## Context
What was decided and why, what was ruled out. Links: commits, files, repos, URLs.

## Tasks
- [ ] Concrete steps, in order, each one actionable on its own.

## Done when
- Checks that prove the work is done.

## Open questions
- ? A question, with the recommended answer when there is one.
```

- Every section is required; `Open questions` may say `None`.
- `project` is optional: omit the line when the work belongs to no project.
- Paths are as seen on the receiver. Never include secrets or tokens.
