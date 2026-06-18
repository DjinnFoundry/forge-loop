---
description: "Task-driven Forge loop with KPI guardrails"
argument-hint: '"SCOPE" [--done-when "TEXT"] --coverage N --speed -N% --quality strict|moderate|lax [--max-iterations N]'
---

# Forge Command

@skills/forge/SKILL.md

This command is the Claude Code driver for Forge Core.

## Arguments

**Arguments provided:** $ARGUMENTS

## Argument Parsing

1. **SCOPE**: Quoted string describing the primary task or area to improve (e.g., "Build password reset flow", "LiveView components")
2. `--done-when "TEXT"`: Optional explicit success override. If omitted, derive concrete completion checks from the task scope and persist them in forge-state.
3. `--coverage N`: Minimum coverage % target (default: current baseline + 2)
4. `--speed -N%`: Speed reduction target as percentage (default: -20% from baseline)
5. `--quality strict|moderate|lax`: Quality gate level (default: moderate)
   - strict: 0 high, 0 medium findings
   - moderate: 0 high, <= 3 medium
   - lax: 0 high, <= 5 medium
6. `--max-iterations N`: Safety limit (default: 20)

If SCOPE is missing, ask what area to focus on.

## Launch Sequence

1. **Measure baseline**: Run test suite with coverage, parse coverage/speed/tests/failures
2. **Generate session ID**: `MMDD-HHMM-SLUG` format (SLUG = 2-3 words from the task)
3. **Establish success contract**:
   - primary task: `SCOPE`
   - explicit success override: `--done-when "TEXT"` if provided
   - otherwise: derive concrete completion checks from the task itself during iteration 1 and persist them in forge-state
4. **Compute targets** from arguments:
   - coverage: `--coverage N` if provided, else `baseline_coverage + 2`
   - speed: `--speed -N%` if provided, compute `baseline_speed * (1 - N/100)`, else `baseline_speed * 0.8`
   - quality: `--quality` value or "moderate"
5. **Create forge state file**: `.claude/forge-state.{session_id}.md` with success contract + baseline + targets
6. **Create loop state file**: `.claude/forge-loop.{session_id}.local.md` with forge prompt
7. **Report** baseline, targets, and begin first iteration

## Loop Prompt (written to state file)

```
Read .claude/forge-state.{session_id}.md and follow The Forge Protocol (A through H).

SCOPE: {parsed scope}
SESSION: {session_id}
DONE WHEN: {explicit done_when or derive from task and record in forge-state}

You are in a forge loop. Each iteration:
A. ORIENT - Read forge-state, check position + trends + stagnation; on iteration 1 detect runtime capabilities (subagents, parallel/Workflow, worktrees, UI tools) and retrieve relevant prior lessons JIT from the project memory ledger
B. MEASURE - Run tests with coverage, capture KPIs
C. EVALUATE - If iteration 1 or every 3rd: spawn fresh-context subagent on SCOPE
D. DECIDE - Pick strategy + plan the iteration (mode: sequential|parallel, verify_depth: light|review|adversarial|panel) from KPI gaps + findings + lessons + capabilities
E. EXECUTE - ONE coherent improvement: a focused change, or the best of a parallel fan-out round (worktree-isolated, cheap-tier workers + strong-tier judge panel) when parallel is warranted
F. VERIFY - Tests must be green; verify at the planned depth (escalate to adversarial refutation for risky/surprising changes); re-measure with coverage
G. RECORD - Update forge-state with deltas + lessons (autoregressive step); compact the log if it grows long
H. COMPLETE - Task success contract satisfied AND KPI targets met (or convergence/budget stop reached)? Write a loop retrospective, then output FORGE_COMPLETE on its own line

Refer to the forge skill for the full protocol (§ Runtime Capabilities, § Model Tiering, § Adaptive Orchestration, § Parallel Rounds, § Verification Depth, § No-Cheat Invariant, § Convergence and Stopping, § Blast-Radius Guard, § Loop Retrospective).

CRITICAL: Do NOT skip steps. Accept ONE coherent improvement per iteration (explore candidates in parallel if you like, but keep only the best).
CRITICAL: Use the runtime's capabilities when present; degrade gracefully when absent. Sequential is always a safe default.
CRITICAL: Parse KPIs from actual test output. Never fabricate numbers. Verify proportionate to risk — never trust a green you did not try to break.
CRITICAL: Never weaken/skip/delete tests, loosen assertions, lower thresholds, or mock away behavior to go green — that is reward hacking; reject it like a red test.
CRITICAL: Stay within blast radius — no out-of-scope edits and no destructive/irreversible git, FS, or external actions in unattended runs; pause instead.
CRITICAL: If tests are red after EXECUTE, fix before RECORD.
CRITICAL: Output control markers (`FORGE_COMPLETE`, `FORGE_PAUSE`, `<promise>...</promise>`) on their own line.
```

## Completion

The forge loop exits via the stop hook mechanism:
- `FORGE_COMPLETE` when the task success contract and KPI targets are satisfied
- `FORGE_PAUSE` if user input is needed
- `--max-iterations` safety limit
- `/forge-cancel` to stop manually
