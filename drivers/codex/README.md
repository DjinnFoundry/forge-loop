# Forge Codex Driver

The Codex driver reuses Forge Core without depending on Claude Code commands or stop
hooks. It runs in two modes: **autonomous** (`forge-run`) and **manual**
(`forge-init` / `forge-continue`).

Forge is task-driven, not just KPI-driven. Each session stores:

- the open-text task scope
- either an explicit `--done-when "TEXT"` success contract or a task-derived one
- the normal KPI guardrails for coverage, speed, quality, and max iterations

## Autonomous (hands-free)

```bash
forge-run "scope" --done-when "what finished means" --coverage 90
```

`forge-run` scaffolds the session, then runs one `codex exec` per iteration (fresh
context each round; state in `.codex/forge/`) until the agent emits `FORGE_COMPLETE`, an
iteration records no progress (stall guard), or max-iterations is reached. It defaults to
`codex exec -c approval_policy=never -c sandbox_mode=workspace-write` so it never blocks on
approval prompts.

Environment overrides:

- `FORGE_CODEX_BIN` — path to the `codex` binary (default `codex`; used by the test mock)
- `FORGE_CODEX_ARGS` — args passed to `codex exec` (default: the two `-c` overrides above)

Resume an interrupted run with `forge-run --session SESSION_ID`.

## Manual (step-by-step)

1. `forge-init "scope" --done-when "what finished means"`
2. Paste the printed prompt into Codex
3. Record iteration results in Forge state
4. Run `forge-continue` for the next prompt
5. Use `forge-status` to inspect scope, success mode, and next iteration

## Files

- `bin/forge-run` — drive the loop autonomously via `codex exec`
- `bin/forge-init` — create a new Forge session for the current project
- `bin/forge-continue` — print the next iteration prompt for an existing session
- `bin/forge-cancel` — cancel the active Codex Forge loop without deleting forge-state
- `bin/forge-status` — show the current Codex Forge session status without mutating state
- `lib.sh` — shared state helpers used by the Codex driver scripts
- `prompt.md` — shared prompt template used by the driver scripts

## State layout

The Codex driver stores state under `.codex/forge/` in the target project:

- `.codex/forge/forge-state.SESSION.md` — Forge Core KPI/state file
- `.codex/forge/loop-state.SESSION.md` — Codex driver loop metadata

The Forge state format stays compatible with Forge Core. Only the driver state
location differs from the Claude Code adapter.

## Safety notes

- `forge-run` stops on a no-progress stall (an iteration that records no `## Iteration N`
  entry) and at max-iterations, so an unproductive loop cannot run forever.
- `forge-continue` derives the next iteration from recorded `## Iteration N`
  entries in Forge state instead of blindly incrementing loop metadata.
- If multiple active Codex sessions exist, `forge-continue` and `forge-cancel`
  require an explicit session id instead of guessing.
- Open-text `scope` and `--done-when` values are persisted in Forge state and
  rendered back into prompts and status output.
