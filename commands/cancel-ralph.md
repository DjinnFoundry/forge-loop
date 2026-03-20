---
description: "Stop the active Forge/Ralph loop in this project"
---

# Cancel Ralph

Stop the active loop for the current project.

## Instructions

1. Look for `.claude/ralph-loop.*.local.md` in the current project.
2. If no loop state files exist, say so and stop.
3. If exactly one loop state file exists, delete it and report which session was cancelled.
4. If multiple loop state files exist:
   - Prefer an `active: true` file over paused ones.
   - If that still leaves more than one candidate, ask the user which session to cancel instead of guessing.
5. Do not delete `.claude/forge-state.*.md`; that file is preserved for inspection.
