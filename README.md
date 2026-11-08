# kit

Reusable Claude Code skills by alxn0, packaged as a plugin.

| Skill | Trigger | Does |
|---|---|---|
| `chat` | `/chat` | Read-only discussion mode: read files, search the web, no code changes |
| `go` | `/go` | Finisher: simplify, test end-to-end, code-review. No commit |
| `python` | auto on `*.py` | Python conventions and tooling (uv, ruff, ty, polars) |
| `ship` | `/ship` | One commit, then push to the allowed branch or open a PR |
| `todo` | `/todo`, auto | Track open items in a managed `TODO.md`: init, convert, add, check. A hook checks the format after each edit |
| `wait` | `/wait` | Present a plan and wait for confirmation before implementing |
| `whereami` | `/whereami` | Print `user@host:cwd` of the session |

## Install

Add to `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "alxn0": { "source": { "source": "github", "repo": "alxn0/kit" }, "autoUpdate": true }
  },
  "enabledPlugins": { "kit@alxn0": true }
}
```

Or from the CLI: `claude plugin marketplace add alxn0/kit && claude plugin install kit@alxn0`.

Skills answer to their bare name (`/go`) unless another skill uses it; then use `/kit:go`.

## Develop

Register the local clone instead of GitHub; it is loaded in place, so edits apply
after `/reload-plugins`:

```bash
claude plugin marketplace add ~/GitHub/alxn0/kit
claude plugin install kit@alxn0
```

Check the layout with `claude plugin validate .`.
