# Forge Stop Hook

The forge loop uses a stop hook to re-inject the prompt after each iteration. This is the same mechanism as the Ralph Wiggum loop — forge creates `ralph-loop.*.local.md` state files that the stop hook reads and re-injects.

## How it works

When Claude Code exits, the stop hook:
1. Checks for an active `.claude/ralph-loop.*.local.md` state file bound to this session
2. If found, reads the last assistant message from the transcript
3. Checks for completion signals (`RALPH_COMPLETE`, `RALPH_PAUSE`, promise tags)
4. If not complete, increments the iteration counter and re-injects the prompt
5. This creates the autoregressive loop — each new iteration sees the updated forge-state file

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

Replace `/path/to/forge-loop` with the actual path where you cloned the repo.

**Already have the Ralph Wiggum stop hook?** Forge works with it automatically — it uses the same `.claude/ralph-loop.*.local.md` state file format. No additional configuration needed.

## Completion signals

The stop hook checks for these signals in the last assistant message:

- `RALPH_COMPLETE` — all targets met, stop the loop and clean up state file
- `RALPH_PAUSE` — user input needed, pause the loop (state file preserved for resume)
- `<promise>TEXT</promise>` — completion promise fulfilled (if `--completion-promise` was set)
- Max iterations reached — safety limit, stop the loop

## State files

### Loop state: `.claude/ralph-loop.SESSION.local.md`

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
- `active`: Set to `paused` on `RALPH_PAUSE`, state file deleted on completion

### Forge KPI state: `.claude/forge-state.SESSION.md`

Tracks KPIs, strategies, and lessons across iterations. This is the autoregressive memory — read by the forge protocol on each ORIENT phase. See the skill docs for the full format.

Both files live in `.claude/` which is typically gitignored. Stale files (>24h) are cleaned up automatically.

## Dependencies

The stop hook requires:
- `jq` — for parsing the hook input JSON and transcript
- `perl` — for extracting `<promise>` tags (standard on macOS/Linux)
- `sed`, `awk`, `grep` — standard Unix tools
