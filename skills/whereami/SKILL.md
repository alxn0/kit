---
name: whereami
description: Print user@host:working_directory of the current session. Slash-command only (/whereami).
disable-model-invocation: true
---

Reply with exactly the line below, in a code span, and nothing else:

!`echo "$(whoami)@$(hostname -s):${PWD/#$HOME/\~}"`
