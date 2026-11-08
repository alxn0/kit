#!/usr/bin/env bash
# Send a handoff brief to the inbox of another machine.
#
# Usage: send.sh <target> <brief>
#   <target>  ssh destination without path: an alias (dixie) or user@host
#   <brief>   local file named <YYYY-MM-DD>-<slug>.md
# Copies <brief> to <target>:inbox/. Fails if the target is not a bare
# [user@]host, if the brief is misnamed or incomplete, or if ~/inbox is
# missing on the target. Exit codes: 0 sent, 1 refused or scp failed, 64 usage.
set -euo pipefail

readonly TARGET_PATTERN='^([A-Za-z0-9._-]+@)?[A-Za-z0-9][A-Za-z0-9._-]*$'
readonly BRIEF_NAME_PATTERN='^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*\.md$'
readonly REQUIRED_LINES=("## Goal" "## Context" "## Tasks" "## Done when" "## Open questions")

fail() { echo "send.sh: $1" >&2; exit 1; }

(($# == 2)) || { echo "usage: send.sh <target> <brief>" >&2; exit 64; }
target="$1"
brief="$2"

# A bare [user@]host keeps scp from writing outside inbox/ or reading an option.
[[ $target =~ $TARGET_PATTERN ]] ||
  fail "target \"$target\" must be an ssh alias or user@host, without path or options"
[[ -f $brief ]] || fail "$brief: not found"
[[ $(basename "$brief") =~ $BRIEF_NAME_PATTERN ]] ||
  fail "$brief: name must be <YYYY-MM-DD>-<slug>.md"
for required_line in "${REQUIRED_LINES[@]}"; do
  grep -q "^$required_line" "$brief" || fail "$brief: missing \"$required_line\""
done

scp -q -- "$brief" "$target:inbox/" ||
  fail "scp to $target:inbox/ failed (does ~/inbox exist on $target?)"
echo "sent $(basename "$brief") to $target:inbox/"
