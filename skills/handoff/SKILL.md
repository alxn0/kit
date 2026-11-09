---
name: handoff
description: Hand work from this session over to another machine's agent - draft a self-contained brief, show it for approval, then copy it to the target's ~/inbox/, or stage it in local ~/send/ for the target to pull. Manual trigger only.
argument-hint: "<target: ssh alias, user@host or --local> [what to hand over]"
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/send.sh *)
---

# Handoff

Request: $ARGUMENTS

The first argument is the target: an ssh alias (`dixie`) or `user@host`, no path; or
`--local` when this machine cannot reach the receiver: the brief is staged in `~/send/`
and the receiver pulls it. No target: ask for it and stop. The rest says what to hand over; empty means the work
discussed in this session.

1. **Draft** the brief following `${CLAUDE_SKILL_DIR}/brief.md`, from this session:
   decisions with their reasons, what was ruled out, commits and files. Write it for a
   reader with no access to this session. Set `project` only when the work belongs
   to a project on the receiver; ask the user if unclear.
2. **Show** the full brief and wait for the user's approval. Apply their changes and
   show it again until approved.
3. **Write** it to `/tmp/handoff/<YYYY-MM-DD>-<slug>.md`.
4. **Send:** `${CLAUDE_SKILL_DIR}/scripts/send.sh <target> <file>`. On failure, relay
   the message and stop; never retry with another target or path.
5. Report the file name and target; with `--local`, also the pull command the script
   prints. The receiver processes it with `/inbox`.
