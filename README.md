# toolshed

A shared Claude Code plugin marketplace of small utilities. Enable only the plugins you want.

| Plugin | Skill | Trigger | Does |
|---|---|---|---|
| `relay` | `handoff` | `/handoff <target>` | Draft a self-contained brief of the session, approve it, copy it to `<target>:inbox/`, or with `--local` stage it in `~/send/` for the receiver to pull |
| | `inbox` | `/inbox` | Plan and do a received brief with approval, then delete it or queue what is left |
| | `whereami` | `/whereami` | Print `user@host:cwd` of the session |
| | `spawn` | `/spawn <folder>` | Start Claude with Remote Control in a detached tmux session in a folder (path, or a word resolved via `z` then `find`, approved by you) |
| `modes` | `chat` | `/chat` | Read-only discussion mode: read files, search the web, no code changes |
| | `wait` | `/wait` | Present a plan and wait for confirmation before implementing |
| | `go` | `/go` | Finisher: simplify, test end-to-end, code-review. No commit |
| `coding` | `python` | auto on `*.py` | Python conventions and tooling (uv, ruff, ty, polars) |
| | `golang` | auto on `*.go` | Go conventions and tooling (mise, gofmt, go vet, staticcheck) |

## Install

Add to `~/.claude/settings.json`, keeping only the plugins you want:

```json
{
  "extraKnownMarketplaces": {
    "toolshed": { "source": { "source": "github", "repo": "alxn0/toolshed" }, "autoUpdate": true }
  },
  "enabledPlugins": {
    "relay@toolshed": true,
    "modes@toolshed": true,
    "coding@toolshed": true
  }
}
```

Or from the CLI:

```bash
claude plugin marketplace add alxn0/toolshed
claude plugin install relay@toolshed   # repeat per plugin
```

Skills answer to their bare name (`/go`) unless another skill uses it; then use `/<plugin>:<skill>`,
e.g. `/modes:go`.

## Layout

```
.claude-plugin/marketplace.json   lists every plugin
plugins/<plugin>/
  .claude-plugin/plugin.json      plugin manifest
  skills/<skill>/SKILL.md         one folder per skill
```

To add a plugin: create `plugins/<plugin>/` with that layout, then add it to `marketplace.json`.
To add a skill to an existing plugin: add `plugins/<plugin>/skills/<skill>/` and list it in the
plugin's `description`.

## Develop

Register the local clone instead of GitHub; it is loaded in place, so edits apply
after `/reload-plugins`:

```bash
claude plugin marketplace add ~/GitHub/alxn0/toolshed
claude plugin install relay@toolshed
```

Check the layout with `claude plugin validate .` (marketplace) or
`claude plugin validate plugins/<plugin>`.
