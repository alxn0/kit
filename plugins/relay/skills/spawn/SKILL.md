---
name: spawn
description: Open a detached tmux session in a folder and start Claude with Remote Control there, so it can be driven from claude.ai/code or the phone. The session is named after the folder unless --name is given. Takes a path or a single word resolved like `j` (z frecency, user approves the match; else find under ~). Use when the user asks to spawn, open or start a remote Claude session or tmux session in a folder.
argument-hint: <word-or-path> [--trust] [--name <name>]
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/spawn.sh *)
---

# Spawn a Remote Control session

Argument: one folder word (`graph`) or a path (`~/GitHub/x/y`, `./sub`), plus
optional flags, passed to `start` only:
- `--trust`: answer Claude's "trust this folder?" prompt with "Yes".
- `--name <name>`: session and Remote Control name instead of the folder's;
  also means another session in an already open folder is deliberate.

Only the user sets these flags. Never add one yourself, not even to retry.
No folder → ask the user for one. One folder per call.

## 1. Resolve the folder

```
${CLAUDE_SKILL_DIR}/scripts/spawn.sh lookup '<argument>'
```

Each output line is `<source><TAB><dir>`:

- `path` → the user typed it; go to step 2 without asking.
- `z` → z's best guess, which can be wrong (z matches substrings anywhere in
  the path). Ask the user to approve it with AskUserQuestion: "Yes, use it" /
  "No, search with find". On "No", run
  `${CLAUDE_SKILL_DIR}/scripts/spawn.sh find '<argument>'` and handle its output
  as below.
- `find` (z missing, no z match, or z rejected) →
  - one line: ask the user to approve it;
  - several: ask the user to pick (AskUserQuestion holds 4 options; above
    that, list them numbered in text and ask).

Non-zero exit: report the message and stop. Never guess a folder the user has
not approved.

## 2. Start the session

```
${CLAUDE_SKILL_DIR}/scripts/spawn.sh start '<dir>' [--trust] [--name '<name>']
```

It names the session (folder name, or `--name`), starts an interactive shell there
(so mise and direnv load), types `claude --remote-control <name>`, waits for
Claude's screen and prints the pane.

Warnings (exit code → what to relay; existing sessions are never touched):
- 3, trust prompt (folder never opened by Claude): the new session was
  stopped. Claude would get read, edit and execute access there; review the
  folder, then rerun `/spawn <argument> --trust`.
- 4, a tmux session is already open in the folder: nothing started. Relay
  the listed panes (they show whether `claude` runs there); attach to it, or
  rerun `/spawn <argument> --name <name>`.
- 5, the name is taken: nothing started. Rerun with `--name <other-name>`.

Report from the output, in a few lines:
- started → give the session URL shown and the attach command.
- Remote Control not active in time → show the relevant pane lines and the
  attach command.
