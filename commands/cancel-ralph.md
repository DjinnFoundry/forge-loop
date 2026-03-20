---
description: "Legacy alias for /forge-cancel"
---

# Cancel Ralph

Legacy alias for `/forge-cancel`.

This command is part of the Claude Code driver for Forge Core.

## Instructions

1. Tell the user `/forge-cancel` is the primary Forge command now.
2. Then perform the same behavior as `/forge-cancel`.
3. Look for active loop state files in this order:
   - `.claude/forge-loop.*.local.md`
   - `.claude/ralph-loop.*.local.md` as a legacy compatibility fallback
4. If no loop state files exist, say so and stop.
5. If exactly one loop state file exists, delete it and report which session was cancelled.
6. If multiple loop state files exist:
   - Prefer an `active: true` file over paused ones.
   - If that still leaves more than one candidate, ask the user which session to cancel instead of guessing.
7. Do not delete `.claude/forge-state.*.md`; that file is preserved for inspection.
