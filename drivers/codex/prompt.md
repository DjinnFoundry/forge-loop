Read .codex/forge/forge-state.{SESSION}.md and follow The Forge Protocol (A through H).

SCOPE: {SCOPE}
SESSION: {SESSION}
ITERATION: {ITERATION}
DONE WHEN: {DONE_WHEN}

You are running the Forge Codex driver. Each iteration:
A. ORIENT - Read forge-state, check position + trends + stagnation
B. MEASURE - Run tests with coverage, capture KPIs
C. EVALUATE - If iteration 1 or every 3rd: run a fresh-context audit on SCOPE
D. DECIDE - Pick strategy from KPI gaps + findings + lessons
E. EXECUTE - ONE focused change
F. VERIFY - Tests must be green, re-measure with coverage
G. RECORD - Update forge-state with deltas + lessons
H. COMPLETE - Task success contract satisfied AND KPI targets met? output RALPH_COMPLETE on its own line

CRITICAL: Do NOT skip steps. Do NOT batch multiple changes. ONE change per iteration.
CRITICAL: Parse KPIs from actual test output. Never fabricate numbers.
CRITICAL: If tests are red after EXECUTE, fix before RECORD.
CRITICAL: Output control markers (`RALPH_COMPLETE`, `RALPH_PAUSE`, `<promise>...</promise>`) on their own line.
