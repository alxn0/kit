#!/bin/bash
set -euo pipefail

# Open a detached tmux session in a folder and start Claude with Remote Control.
# The session and the Remote Control name are both the folder's basename.
#
#   spawn.sh lookup <word-or-path>  Resolve a folder: a path as given, else z, else find.
#   spawn.sh find <word>            Find folders named exactly <word> under $HOME.
#   spawn.sh start <dir> [--trust] [--name <name>]
#                                   Create the session, start Claude, print the pane.
#
# lookup/find print one "<source><TAB><dir>" line per candidate, source being
# path, z or find. The caller approves z and find results before start.
#
# start warns and starts nothing when a tmux session is already open in <dir>
# (EXIT_FOLDER_OPEN; --name skips this check) or the name is taken
# (EXIT_NAME_TAKEN). On Claude's "trust this folder?" prompt: without --trust,
# stops the new session (EXIT_UNTRUSTED); with --trust, answers "Yes".

# Depth and pruned names for find: hidden dirs and tool-managed or build trees.
FIND_MAX_DEPTH=5
FIND_PRUNED_NAMES=('.*' node_modules go R target)
# Seconds to wait for each expected screen before giving up and printing the pane.
SCREEN_TIMEOUT_SECONDS=20
# Screen text Claude Code (v2.1) shows once Remote Control runs, and on the trust prompt.
REMOTE_CONTROL_ACTIVE_TEXT='remote-control is active'
TRUST_PROMPT_YES_TEXT='Yes, I trust this folder'
EXIT_UNTRUSTED=3
EXIT_FOLDER_OPEN=4
EXIT_NAME_TAKEN=5

die() {
  echo "spawn: $*" >&2
  exit 1
}

# Print the folder z ranks best for <word>; non-zero if z is missing or has no match.
lookup_with_z() {
  local word="$1"
  local z_script="${_Z_SCRIPT:-$HOME/.z.sh}"
  if [[ ! -r "$z_script" ]]; then
    echo "spawn: z not installed ($z_script); using find" >&2
    return 1
  fi
  # z.sh is not written for set -u; it also must not install its prompt hook.
  (
    set +u
    _Z_NO_PROMPT_COMMAND=1
    # shellcheck source=/dev/null
    . "$z_script"
    _z -e "$word"
  )
}

# Print every folder under $HOME named exactly <word>, sorted.
find_in_home() {
  local word="$1"
  local prune=() name
  for name in "${FIND_PRUNED_NAMES[@]}"; do
    prune+=(-o -name "$name")
  done
  find "$HOME" -mindepth 1 -maxdepth "$FIND_MAX_DEPTH" \
    \( "${prune[@]:1}" \) -prune -o -type d -name "$word" -print 2>/dev/null | sort
}

# Reject words find or z would read as patterns.
require_plain_word() {
  [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]] || die "not a folder name: '$1' (letters, digits, . _ - only)"
}

command_find() {
  local word="$1" matches
  require_plain_word "$word"
  matches="$(find_in_home "$word")"
  [[ -n "$matches" ]] || die "no folder named '$word' under $HOME (depth $FIND_MAX_DEPTH)"
  local match
  while IFS= read -r match; do
    printf 'find\t%s\n' "$match"
  done <<<"$matches"
}

command_lookup() {
  local query="$1" dir
  # Anything with a slash, or ~ / ., is a path: use it as given.
  if [[ "$query" == */* || "$query" == "~" || "$query" == "." ]]; then
    query="${query/#\~/$HOME}"
    dir="$(realpath -e -- "$query" 2>/dev/null)" || die "no such path: $1"
    [[ -d "$dir" ]] || die "not a directory: $dir"
    printf 'path\t%s\n' "$dir"
    return
  fi
  require_plain_word "$query"
  if dir="$(lookup_with_z "$query")" && [[ -n "$dir" ]]; then
    printf 'z\t%s\n' "$dir"
    return
  fi
  command_find "$query"
}

pane_text() {
  tmux capture-pane -p -t "=$1:"
}

# Wait until the pane of session <name> shows one of the given texts; print the
# matching text, or nothing on timeout.
wait_for_screen() {
  local name="$1" waited=0 pane text
  shift
  while ((waited < SCREEN_TIMEOUT_SECONDS)); do
    sleep 1
    waited=$((waited + 1))
    pane="$(pane_text "$name")"
    for text in "$@"; do
      if grep -qF -- "$text" <<<"$pane"; then
        echo "$text"
        return
      fi
    done
  done
}

# Select "Yes" on the trust prompt (the default is "No, exit") and confirm,
# only once the cursor is verifiably on "Yes".
accept_trust_prompt() {
  local name="$1"
  tmux send-keys -t "=$name:" Down
  sleep 0.5
  if ! pane_text "$name" | grep -qF -- "❯ $TRUST_PROMPT_YES_TEXT"; then
    tmux kill-session -t "=$name"
    die "could not select '$TRUST_PROMPT_YES_TEXT' on the trust prompt; session '$name' stopped"
  fi
  tmux send-keys -t "=$name:" Enter
}

# Print a warning and exit with <code>, leaving every existing session untouched.
warn_and_exit() {
  local code="$1"
  shift
  echo "spawn: WARNING: $*" >&2
  exit "$code"
}

# Print one line per tmux pane whose session started in <dir> or which is now in it.
list_panes_in_folder() {
  local dir="$1" target session_path pane_path command
  tmux list-panes -a -F \
    $'#{session_name}:#{window_index}.#{pane_index}\t#{session_path}\t#{pane_current_path}\t#{pane_current_command}' \
    2>/dev/null |
    while IFS=$'\t' read -r target session_path pane_path command; do
      if [[ "$session_path" == "$dir" || "$pane_path" == "$dir" ]]; then
        echo "  $target in $pane_path (session started in $session_path), running $command"
      fi
    done
}

command_start() {
  local dir name="" screen panes is_trust_allowed=false is_name_given=false
  dir="$(realpath -e -- "$1" 2>/dev/null)" || die "no such path: $1"
  [[ -d "$dir" ]] || die "not a directory: $dir"
  shift
  while (($# > 0)); do
    case "$1" in
      --trust) is_trust_allowed=true ;;
      --name)
        [[ $# -ge 2 ]] || die "--name needs a value"
        name="$2"
        is_name_given=true
        shift
        ;;
      *) die "unknown start option: $1 (--trust, --name <name>)" ;;
    esac
    shift
  done

  if [[ "$is_name_given" == true ]]; then
    [[ "$name" =~ ^[A-Za-z0-9_-]+$ ]] || die "invalid name: '$name' (letters, digits, _ - only)"
  else
    name="$(basename "$dir")"
    name="${name//[^A-Za-z0-9_-]/_}" # tmux forbids . and : in session names
    # An explicit --name means a second session in the folder is deliberate.
    panes="$(list_panes_in_folder "$dir")"
    if [[ -n "$panes" ]]; then
      warn_and_exit "$EXIT_FOLDER_OPEN" "a tmux session is already open in $dir:"$'\n'"$panes"$'\n'"Nothing started. Attach to it, or rerun with --name <name> for another session."
    fi
  fi

  if tmux has-session -t "=$name" 2>/dev/null; then
    warn_and_exit "$EXIT_NAME_TAKEN" "a tmux session named '$name' already exists" \
      "(started in $(tmux display-message -p -t "=$name:" '#{session_path}'))." \
      "Nothing started. Rerun with --name <other-name>."
  fi

  # Interactive shell first, so bashrc (mise, direnv) loads before claude runs.
  tmux new-session -d -s "$name" -c "$dir"
  tmux send-keys -t "=$name:" -l "claude --remote-control $(printf '%q' "$name")"
  tmux send-keys -t "=$name:" Enter

  screen="$(wait_for_screen "$name" "$REMOTE_CONTROL_ACTIVE_TEXT" "$TRUST_PROMPT_YES_TEXT")"
  if [[ "$screen" == "$TRUST_PROMPT_YES_TEXT" ]]; then
    if [[ "$is_trust_allowed" != true ]]; then
      tmux kill-session -t "=$name"
      echo "spawn: WARNING: Claude has never been trusted in $dir; it would get" \
        "read, edit and execute access there. Session '$name' stopped." \
        "Review the folder, then rerun with --trust to answer 'Yes' automatically." >&2
      exit "$EXIT_UNTRUSTED"
    fi
    echo "Trust prompt answered 'Yes' for $dir (--trust)."
    accept_trust_prompt "$name"
    screen="$(wait_for_screen "$name" "$REMOTE_CONTROL_ACTIVE_TEXT")"
  fi

  if [[ "$screen" == "$REMOTE_CONTROL_ACTIVE_TEXT" ]]; then
    echo "Session '$name' started in $dir. Pane:"
  else
    echo "Session '$name' created in $dir, but Remote Control did not show as active within ${SCREEN_TIMEOUT_SECONDS}s. Pane:"
  fi
  echo "----"
  pane_text "$name" | grep -v '^[[:space:]]*$' | tail -n 25
  echo "----"
  echo "Attach: tmux attach -t $name"
}

usage="usage: spawn.sh lookup|find <arg> | spawn.sh start <dir> [--trust] [--name <name>]"
[[ $# -ge 2 ]] || die "$usage"
case "$1" in
  lookup) [[ $# -eq 2 ]] || die "$usage"; command_lookup "$2" ;;
  find) [[ $# -eq 2 ]] || die "$usage"; command_find "$2" ;;
  start) shift; command_start "$@" ;;
  *) die "unknown command: $1 (lookup, find or start)" ;;
esac
