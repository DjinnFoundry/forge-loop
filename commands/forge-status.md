---
description: "Show Forge Claude Code driver status for this project"
---

# Forge Status

Show the current Claude Code driver status for this project.

## Instructions

1. Look for `.claude/ralph-loop.*.local.md` and matching `.claude/forge-state.*.md` files.
2. If no loop state files exist, say there is no active or paused Claude driver session.
3. If multiple loop state files exist:
   - list them
   - prefer `active: true` for the default summary
   - if more than one active session exists, say so explicitly instead of pretending there is one session
4. For each reported session, show:
   - session id
   - active/paused state
   - iteration
   - max_iterations
   - forge-state path if present
5. If the forge-state file exists, also show:
   - scope
   - current strategy
   - stagnation_count
6. Do not mutate any files. This command is read-only.
