---
description: "Show Forge Claude Code driver status for this project"
---

# Forge Status

Show the current Claude Code driver status for this project.

## Instructions

1. Look for loop state files in this order and match them to `.claude/forge-state.*.md` files:
   - `.claude/forge-loop.*.local.md`
   - `.claude/ralph-loop.*.local.md` as a legacy compatibility fallback
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
   - success mode
   - done_when text, or that it is task-derived if no explicit override exists
   - current strategy
   - stagnation_count
   - whether completion checks have been recorded yet if the success block is present
6. Do not mutate any files. This command is read-only.
