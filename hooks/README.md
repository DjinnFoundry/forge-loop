# Forge Claude Code Driver: Stop Hook

This file documents the Claude Code driver for Forge. The hook re-injects the next iteration prompt after each Claude Code session exit.

Forge is directly inspired by Ralph Wiggum's loop pattern. The driver now uses
`forge-loop.*.local.md` as the primary loop-state file name while still
accepting legacy `ralph-loop.*.local.md` files for compatibility.

## How it works

When Claude Code exits, the stop hook:
1. Checks for an active `.claude/forge-loop.*.local.md` state file bound to this session
2. Falls back to legacy `.claude/ralph-loop.*.local.md` state files if needed
3. If found, reads the last assistant message from the transcript
4. Checks for exact control lines (`FORGE_COMPLETE`, `FORGE_PAUSE`, promise tags)
5. If not complete, increments the iteration counter and re-injects the prompt
6. This creates the autoregressive loop — each new iteration sees the updated forge-state file

## Setup

Add this to your `~/.claude/settings.json` under the `hooks` key:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/forge-loop/hooks/stop-hook.sh"
          }
        ]
      }
    ]
  }
}
```

If you ran `./install.sh`, the stable local path is:

```json
"command": "$HOME/.claude/hooks/stop-hook.sh"
```

Legacy Ralph state files and control markers are still accepted during migration.

No native Codex driver is shipped here. This hook is Claude Code-specific.

## Completion signals

The stop hook checks for these exact control lines in the last assistant message:

- `FORGE_COMPLETE` — all targets met, stop the loop and clean up state file
- `FORGE_PAUSE` — user input needed, pause the loop and preserve the state file
- `<promise>TEXT</promise>` — completion promise fulfilled when emitted on its own line (if `--completion-promise` was set)
- Max iterations reached — safety limit, stop the loop

Legacy `RALPH_COMPLETE` and `RALPH_PAUSE` markers are still accepted.

## State files

### Loop state: `.claude/forge-loop.SESSION.local.md`

Controls the iteration engine. Format:

```yaml
---
active: true
session_id: "0320-1430-a3b2"
session_transcript: null
iteration: 1
max_iterations: 20
completion_promise: null
started_at: "2026-03-20T14:30:00Z"
---

[The prompt that gets re-injected each iteration]
```

Key fields:
- `session_transcript`: Set to `null` initially, claimed by the first session that runs the stop hook. Binds the state file to one Claude Code session.
- `iteration`: Incremented by the stop hook on each cycle
- `active`: Set to `paused` on `FORGE_PAUSE`; paused loop files are ignored until you manually set them back to `true` or start a fresh loop

Legacy `.claude/ralph-loop.SESSION.local.md` files are still accepted.

### Forge KPI state: `.claude/forge-state.SESSION.md`

Tracks KPIs, strategies, and lessons across iterations. This is the autoregressive memory — read by the forge protocol on each ORIENT phase. See the skill docs for the full format.

Both files live in `.claude/` which is typically gitignored. Stale files (>24h) are cleaned up automatically.

## Dependencies

The stop hook requires:
- `jq` — for parsing the hook input JSON and transcript
- `sed`, `awk`, `grep` — standard Unix tools
