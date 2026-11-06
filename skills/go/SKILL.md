---
description: Finisher for /go — after work is done, verify end-to-end, simplify the diff, then commit and push to the branch the repo's rules allow, or open a PR. Manual trigger only.
disable-model-invocation: true
---

## When to use

Use this skill when the user ends a prompt with `/go` or explicitly invokes `/go`. Typical usage: "build feature X /go" or "fix bug Y /go". The `/go` is a signal that Claude should finish the job — verify it works, simplify it, and ship it — not just write the code and stop.

## What this skill does

After the preceding work is complete, runs a three-step finisher:

1. **Verify end-to-end** — prove the change actually works
2. **Simplify** — remove unneeded abstraction, comments, and dead code
3. **Ship** — commit, then push to an allowed branch or open a PR

Do all three. Don't ask for permission between steps. If a step fails, fix it and continue; don't stop and wait.

## Step 1 — Verify end-to-end

Do not trust type checks or unit tests alone. Exercise the actual feature from the user's perspective.

Pick the right verification method for the task:

- **Backend / API / CLI** — start the server or run the command, hit the endpoint with `curl`, or invoke the CLI with real arguments. Check the response body, exit code, and logs.
- **Frontend / web UI** — start the dev server. Use the Chrome DevTools MCP or Claude Chromium extension if available to click through the golden path. If no browser control is available, say so explicitly rather than claiming it works.
- **Chrome extension** — load the unpacked extension, reload it, open the target page, check the console for errors.
- **Data pipeline / script** — run it against a real (or realistic) input and inspect the output.
- **Desktop app** — use computer use if available; otherwise state that manual verification is needed.

When verifying:
- Test the golden path AND at least one edge case (empty input, error state, auth failure, etc).
- Watch for regressions — does an adjacent feature still work?
- Read stderr and server logs, not just stdout.
- If you can't verify (no browser, no creds, no test data), say so explicitly. Do not pretend.

If verification fails, fix the root cause and re-verify. Do not paper over it.

## Step 2 — Simplify

Invoke the `/simplify` skill on the diff. It reviews changed code for reuse, quality, and efficiency and fixes any issues found.

Do not skip this step. Do not do it inline. Call the skill.

## Step 3 — Ship

```bash
git status
git diff
git log --oneline -5        # match the repo's commit style
```

Pick the ship target, first match wins:

1. **Worktree** — `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`:
   push the current branch and open a PR. Skip the rule check below.
2. **Explicit rule** — the global or project `CLAUDE.md` (or `CONTRIBUTING.md`) says you may
   commit and push directly to `main` or to a named branch (e.g. `staging`): commit on that
   branch and push it. No PR.
3. **Default** — create a feature branch if on the default branch, push it, and open a PR.

Then:

1. Stage only the files you touched (name them explicitly, don't `git add -A`).
2. Create a NEW commit (never `--amend` unless the user asks). Use a HEREDOC for the message.
3. Push to the remote with `-u` if the branch isn't tracked yet.
4. If the target needs a PR, open it with `gh pr create` using a HEREDOC body.

Commit message style:
- One-line subject, under 70 chars, imperative mood ("add X", "fix Y", not "added" / "fixes")
- Body explains the WHY, not the WHAT — the diff shows what

PR body template:
```
## Summary
- <1-3 bullets on the change>

## Verification
- <what you actually ran to confirm it works>
- <edge cases checked>

## Test plan
- [ ] <checklist item for reviewer>

Generated with Claude Code
```

Return the PR URL (or the pushed branch and commit) at the end.

## Guardrails

- **Never** force-push, reset --hard, or skip hooks (`--no-verify`) unless the user explicitly asks.
- **Never** push directly to `main` / `master` unless an explicit rule allows it (see Step 3).
- **Never** commit `.env`, credentials, or other secrets — warn the user if any are staged.
- If a pre-commit hook fails, FIX the underlying issue and create a NEW commit. Do not amend and do not bypass.
- If you genuinely cannot verify (no access to a browser / creds / external service), still ship but state exactly what was NOT verified (in the PR body, or in the summary when pushed directly).

## Output

At the end of `/go`, print a compact summary:

```
Verified: <one line — what you ran and what you saw>
Simplified: <one line — what you removed, or "nothing to simplify">
Shipped: <PR URL, or branch and commit hash when pushed directly>
```

Nothing else. The user can read the diff.
