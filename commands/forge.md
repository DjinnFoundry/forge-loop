---
description: "KPI-driven codebase improvement loop"
argument-hint: '"SCOPE" --coverage N --speed -N% --quality strict|moderate|lax [--max-iterations N]'
---

# Forge Command

@skills/forge/SKILL.md

## Arguments

**Arguments provided:** $ARGUMENTS

## Argument Parsing

1. **SCOPE**: Quoted string describing what to improve (e.g., "LiveView components", "API controllers")
2. `--coverage N`: Minimum coverage % target (default: current baseline + 2)
3. `--speed -N%`: Speed reduction target as percentage (default: -20% from baseline)
4. `--quality strict|moderate|lax`: Quality gate level (default: moderate)
   - strict: 0 high, 0 medium findings
   - moderate: 0 high, <= 3 medium
   - lax: 0 high, <= 5 medium
5. `--max-iterations N`: Safety limit (default: 20)

If SCOPE is missing, ask what area to focus on.

## Launch Sequence

1. **Measure baseline**: Run test suite with coverage, parse coverage/speed/tests/failures
2. **Generate session ID**: `MMDD-HHMM-XXXX` format
3. **Compute targets** from arguments:
   - coverage: `--coverage N` if provided, else `baseline_coverage + 2`
   - speed: `--speed -N%` if provided, compute `baseline_speed * (1 - N/100)`, else `baseline_speed * 0.8`
   - quality: `--quality` value or "moderate"
4. **Create forge state file**: `.claude/forge-state.SESSION.md` with baseline + targets
5. **Create loop state file**: `.claude/ralph-loop.SESSION.local.md` with forge prompt
6. **Report** baseline, targets, and begin first iteration

## Loop Prompt (written to state file)

```
Read .claude/forge-state.SESSION.md and follow The Forge Protocol (A through H).

SCOPE: {parsed scope}
SESSION: {session_id}

You are in a forge loop. Each iteration:
A. ORIENT - Read forge-state, check position + trends + stagnation
B. MEASURE - Run tests with coverage, capture KPIs
C. EVALUATE - If iteration 1 or every 3rd: spawn fresh-context subagent on SCOPE
D. DECIDE - Pick strategy from KPI gaps + findings + lessons
E. EXECUTE - ONE focused change using appropriate subagent
F. VERIFY - Tests must be green, re-measure with coverage
G. RECORD - Update forge-state with deltas + lessons (autoregressive step)
H. COMPLETE - ALL targets met simultaneously? → RALPH_COMPLETE

Refer to the forge skill for the full protocol.

CRITICAL: Do NOT skip steps. Do NOT batch multiple changes. ONE change per iteration.
CRITICAL: Parse KPIs from actual test output. Never fabricate numbers.
CRITICAL: If tests are red after EXECUTE, fix before RECORD.
```

## Completion

The forge loop exits via the stop hook mechanism:
- `RALPH_COMPLETE` when all KPI targets met simultaneously
- `RALPH_PAUSE` if user input needed
- `--max-iterations` safety limit
- `/cancel-ralph` to stop manually
