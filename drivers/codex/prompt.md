Read .codex/forge/forge-state.{SESSION}.md and follow The Forge Protocol (A through H).

SCOPE: {SCOPE}
SESSION: {SESSION}
ITERATION: {ITERATION}
DONE WHEN: {DONE_WHEN}

You are running the Forge Codex driver. Each iteration:
A. ORIENT - Read forge-state, check position + trends + stagnation; on iteration 1 detect runtime capabilities
B. MEASURE - Run tests with coverage, capture KPIs
C. EVALUATE - If iteration 1 or every 3rd: run a fresh-context audit on SCOPE
D. DECIDE - Pick strategy + plan the iteration (mode + verify_depth) from KPI gaps + findings + lessons
E. EXECUTE - ONE coherent improvement
F. VERIFY - Tests must be green; verify at the planned depth (escalate to adversarial refutation for risky/surprising changes); re-measure with coverage
G. RECORD - Update forge-state with deltas + lessons; compact the log if it grows long
H. COMPLETE - Task success contract satisfied AND KPI targets met (or a convergence/budget stop reached)? output FORGE_COMPLETE on its own line

NOTE: Codex runs sequentially by default. Use subagents/`git worktree` for parallel rounds only if available; otherwise try candidate strategies one at a time. See § Runtime Capabilities.

CRITICAL: Do NOT skip steps. Accept ONE coherent improvement per iteration (you may explore candidates, but keep only the best).
CRITICAL: Parse KPIs from actual test output. Never fabricate numbers.
CRITICAL: If tests are red after EXECUTE, fix before RECORD.
CRITICAL: Output control markers (`FORGE_COMPLETE`, `FORGE_PAUSE`, `<promise>...</promise>`) on their own line.
