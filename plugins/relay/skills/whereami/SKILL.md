---
name: whereami
description: Print user@host:working_directory of the current session. Slash-command only (/whereami).
disable-model-invocation: true
---

Reply with exactly `USER@HOST:DIR` in a code span, and nothing else, where:

- USER is !`whoami`
- HOST is !`hostname -s`
- DIR is !`pwd`, with the home directory prefix written as `~`
