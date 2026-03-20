---
description: "Stop the active Forge loop in this project"
---

# Forge Cancel

Stop the active loop for the current project.

This command is part of the Claude Code driver for Forge Core.

## Instructions

1. Look for active loop state files in this order:
   - `.claude/forge-loop.*.local.md`
   - `.claude/ralph-loop.*.local.md` as a legacy compatibility fallback
2. If no loop state files exist, say so and stop.
3. If exactly one loop state file exists, delete it and report which session was cancelled.
4. If multiple loop state files exist:
   - Prefer an `active: true` file over paused ones.
   - If that still leaves more than one candidate, ask the user which session to cancel instead of guessing.
5. Do not delete `.claude/forge-state.*.md`; that file is preserved for inspection.
