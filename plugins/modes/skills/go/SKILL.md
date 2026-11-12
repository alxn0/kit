---
description: Finisher for /go — after work is done, simplify the diff, test it end-to-end, then code-review it. Does not commit or push. Manual trigger only.
disable-model-invocation: true
---

## When to use

The user ends a prompt with `/go` or invokes `/go`, e.g. "build feature X /go". It means: finish
the job — clean it up, prove it works, review it — not just write the code and stop.

`/go` never commits or pushes. If the user also asks to commit ("/go and commit"), do it after
the summary, following the git rules of the global and project `CLAUDE.md`.

## Steps

Run all three, in order. Don't ask for permission between steps. If a step fails, fix the root
cause and continue.

1. **Simplify** — invoke the `simplify` skill on the diff. Call the skill; don't do it inline.
2. **Test** — prove the change works (see below).
3. **Code review** — invoke the `code-review` skill on the diff. Fix confirmed findings, then
   re-run the tests touched by the fixes.

## Step 2 — Test

Run the project's tests, linters and type checks. Then exercise the feature from the user's
perspective: type checks and unit tests alone are not proof.

- **Backend / API / CLI** — run the server or command with real arguments, hit endpoints with
  `curl`. Check response body, exit code and logs.
- **Frontend / web UI** — start the dev server and click through the golden path with browser
  tools if available.
- **Data pipeline / script** — run it on real (or realistic) input and inspect the output.
- **Desktop app** — use computer use if available.

Test the golden path AND at least one edge case (empty input, error state, auth failure).
Check that adjacent features still work. Read stderr and logs, not just stdout.

If you can't test something (no browser, no creds, no test data), say so explicitly. Never
claim it works.

## Output

Print a compact summary, nothing else:

```
Simplified: <what changed, or "nothing to simplify">
Tested: <what you ran and what you saw; what could NOT be tested>
Reviewed: <findings fixed, findings left with reason, or "no findings">
```
