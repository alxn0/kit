#!/usr/bin/env bash
# List handoff briefs waiting in ~/inbox: one line per brief, "<file>  <title>".
# Prints "inbox empty" when there is none. Read-only.
set -euo pipefail

readonly INBOX_DIR="$HOME/inbox"

shopt -s nullglob
briefs=("$INBOX_DIR"/*.md)
if ((${#briefs[@]} == 0)); then
  echo "inbox empty"
  exit 0
fi
for brief in "${briefs[@]}"; do
  title=$(grep -m1 '^# ' "$brief" || echo "# (no title)")
  echo "$(basename "$brief")  ${title#"# "}"
done
