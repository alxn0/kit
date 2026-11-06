---
description: Ship the session's work — one commit, then push to the branch the repo's rules allow, or open a PR. Does not test or review (that's /go). Manual trigger only.
disable-model-invocation: true
---

## When to use

The user invokes `/ship`, or asks to ship after `/go` ("/go then ship"). Ship only the changes
made in this session. Changes the user made by hand are not this skill's job.

## Steps

1. **Inspect** — `git status`, `git diff`, `git log --oneline -10` (match the commit style).
   Uncommitted changes that did not come from this session: STOP and ask which files to ship.
2. **Pick the target**, first match wins:
   1. **Worktree** — `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`:
      push the current branch, open a PR.
   2. **Explicit rule** — the global or project `CLAUDE.md` (or `CONTRIBUTING.md`) allows
      pushing directly to `main` or a named branch (e.g. `staging`): commit on that branch,
      push it. No PR.
   3. **Default** — on the default branch, create a feature branch first. Push it, open a PR.
3. **Commit** — ONE new commit. Stage files by name. Message style, attribution trailers and
   pre-push checks follow `CLAUDE.md`; don't add your own.
4. **Push** — with `-u` if the branch is not tracked yet.
5. **PR** (if the target needs one) — `gh pr create`, body from a HEREDOC:

   ```
   ## Summary
   - <1-3 bullets>

   ## Testing
   - <the /go "Tested" line if /go ran this session, else "Not tested">
   ```

## Guardrails

- Never force-push, `--no-verify`, `--amend` or `reset --hard` unless the user explicitly asks.
- Never commit secrets (`.env`, credentials, tokens). Staged by mistake: unstage and warn.
- Hook fails: fix the root cause, make a NEW commit.

## Output

One line, nothing else:

```
Shipped: <PR URL> | <branch> @ <short hash>
```
