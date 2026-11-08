---
name: handoff
description: Hand work from this session over to another machine's agent - draft a self-contained brief, show it for approval, then copy it to the target's ~/inbox/. Manual trigger only.
argument-hint: "<target: ssh alias or user@host> [what to hand over]"
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/send.sh *)
---

# Handoff

Request: $ARGUMENTS

The first argument is the target: an ssh alias (`dixie`) or `user@host`, no path. No
target: ask for it and stop. The rest says what to hand over; empty means the work
discussed in this session.

1. **Draft** the brief following `${CLAUDE_SKILL_DIR}/brief.md`, from this session:
   decisions with their reasons, what was ruled out, commits and files. Write it for a
   reader with no access to this session. Ask the user for the receiver's `project`
   path if the session does not make it clear.
2. **Show** the full brief and wait for the user's approval. Apply their changes and
   show it again until approved.
3. **Write** it to `/tmp/handoff/<YYYY-MM-DD>-<slug>.md`.
4. **Send:** `${CLAUDE_SKILL_DIR}/scripts/send.sh <target> <file>`. On failure, relay
   the message and stop; never retry with another target or path.
5. Report the file name and target. The receiver processes it with `/inbox`.
