---
name: forge
description: "Task-driven Forge loop with KPI guardrails (coverage/speed/quality). Strategy rotation on stagnation, fresh-context evaluation. Triggers: 'forge it', 'forge this', 'forge loop', 'quality loop', 'kpi loop', 'improvement loop'."
triggers:
  - "forge it"
  - "forge this"
  - "forge loop"
  - "quality loop"
  - "kpi loop"
  - "improvement loop"
  - "codebase improvement loop"
---

# The Forge — Core Protocol Plus Claude Code and Codex Drivers

A structured, task-driven improvement protocol with KPI guardrails. Forge tracks coverage/speed/quality with baselines and targets, derives or records success criteria for the task itself, evaluates with fresh-context audits, rotates strategies when stagnating, and records lessons across iterations. It is single-agent and sequential by default, but **capability-aware**: when the runtime offers parallel sub-agents, worktree isolation, or judge panels, Forge adaptively fans out and verifies harder — spending effort proportionate to opportunity and risk.

Built on the Ralph Wiggum loop pattern (Geoff Huntley), informed by Karpathy's autoregressive philosophy, pi-autoresearch's measurement discipline, and SICA's compounding iteration approach.

## Activation Triggers
- "forge it", "forge this", "forge loop"
- "quality loop", "kpi loop", "improvement loop"
- "codebase improvement loop"
- When user wants structured, KPI-driven autonomous improvement

## Architecture

```
Forge Core
  ├── Protocol phases (A through H)
  ├── State format and KPI model
  ├── Strategy selection + stagnation logic
  └── Fresh-context evaluation expectations

Claude Code driver
  ├── /forge command
  ├── /forge-cancel command
  ├── .claude/forge-state.SESSION.md
  ├── .claude/forge-loop.SESSION.local.md
  └── Stop hook re-injects prompt on session exit

Each iteration (one OODA cycle):
  ├── A. ORIENT   — Read forge-state, understand position + trends, detect capabilities
  ├── B. MEASURE  — Run tests, capture KPIs
  ├── C. EVALUATE — Every 3rd iteration: fresh-context reality-check subagent
  ├── D. DECIDE   — Pick strategy + plan the iteration (mode + verification depth)
  ├── E. EXECUTE  — Apply ONE coherent improvement (sequential, or best-of-N parallel round)
  ├── F. VERIFY   — Run tests, verify at the planned depth, re-measure KPIs
  ├── G. RECORD   — Update forge-state with deltas + lessons (compact if long)
  └── H. COMPLETE — Task success + KPI guardrails + convergence/budget → FORGE_COMPLETE
```

## Driver model

Forge has two layers:

- **Forge Core** — portable protocol, state model, KPI semantics, strategies, and completion rules
- **Success contract** — task objective plus explicit or derived completion checks
- **Driver** — runtime-specific integration that launches the loop, persists state, and handles pause/continue mechanics

Forge currently ships two first-class drivers:

- **Claude Code** — command, agent, and stop-hook integration are bundled here
- **Codex** — `forge-init`, `forge-continue`, `forge-cancel`, and `forge-status` manage a manual loop with project-local state

Other environments can reuse Forge Core manually, but should not be described as
officially supported unless they ship a real driver.

## Runtime Capabilities

Forge Core is single-agent and sequential by default — it always works that way.
But when the runtime offers more, Forge uses more. The protocol describes
capabilities *abstractly*; each driver maps them to whatever the host actually
provides, and Forge detects what is available at runtime rather than assuming.

### Abstract capabilities

| Capability | Meaning | Sequential fallback |
|------------|---------|---------------------|
| `fresh_context_eval` | Spawn an isolated reviewer/auditor with no loop state | Self-review against a checklist |
| `parallel_agents` | Run multiple sub-agents concurrently | Run candidate strategies one at a time |
| `worktree_isolation` | Give each parallel agent an isolated working copy | Serialize edits on the one tree |
| `workflow_orchestration` | Deterministic fan-out/fan-in / pipeline primitive | Hand-rolled sequential loop |
| `ui_quality_tools` | Registered design/UX evaluation tooling | Built-in UI checklist (§ UI Quality Gate) |

**Every capability has a fallback.** The protocol NEVER requires parallelism,
worktrees, or any specific tool. A capability that is absent degrades to its
sequential equivalent — the loop still converges, just slower.

### Driver capability map

| Capability | Claude Code | Codex | Protocol-only |
|------------|:-----------:|:-----:|:-------------:|
| `fresh_context_eval` | ✅ subagents | ✅ subagents | ⚪ self-review |
| `parallel_agents` | ✅ concurrent subagents / Workflow | 🔸 limited | ⚪ |
| `worktree_isolation` | ✅ Workflow `isolation: worktree` / `git worktree` | 🔸 manual `git worktree` | ⚪ |
| `workflow_orchestration` | ✅ Workflow tool (fan-out, pipeline, judge panels) | ⚪ | ⚪ |
| `ui_quality_tools` | ✅ if design skills installed | 🔸 if available | ⚪ checklist |

✅ first-class · 🔸 partial/manual · ⚪ fallback only

### Detection (ORIENT, first iteration)

Do not assume — **detect**. On the first iteration, inventory what the current
runtime exposes (available agent/subagent tools, an orchestration/workflow
primitive, worktree support, registered UI tools) and record a `capabilities`
block in forge-state. Re-use it on later iterations; re-detect only if the
environment changed. When in doubt about a capability, treat it as absent and
take the fallback — correctness over cleverness.

## Adaptive Orchestration

This is the brain that makes Forge "smart enough to decide what to run when."
Running every check on every change is wasteful; running none is reckless.
Each iteration, after sizing the KPI gaps, Forge plans *how* to execute and
*how hard* to verify, proportional to opportunity and risk.

The plan has three dimensions, decided in DECIDE and recorded as `iteration_plan`
in forge-state:

1. **Execution mode** — sequential vs. parallel round
   - **Parallel round** when `parallel_agents` is available AND there are ≥2
     independent, high-value gaps/strategies AND the scope decomposes into
     non-conflicting areas. Fan out one agent per strategy/dimension, then
     fan in (§ Parallel Rounds). This is the screenshot: `Round N · K agents`.
   - **Sequential** when one gap dominates, the change is tightly coupled, the
     capability is absent, or you are doing final polish near completion.

2. **Verification depth** — how skeptically to check the result (§ Verification Depth)
   - Scale to the change's **risk**: blast radius (files/LOC touched),
     criticality (auth, data, money, migrations, public API), KPI surprise
     (a suspiciously large jump), and reversibility.
   - Low risk → tests + light self-review. Medium → fresh-context review.
     High/critical or surprising KPIs → adversarial verification. Competing
     candidates → judge panel.
   - Spend verification where it is *worth it*. Don't gate a typo fix behind a
     judge panel; don't let a migration through on a self-review.

3. **Discovery mode** — bounded vs. loop-until-dry
   - When the task is "find an unknown-size set" (bugs, coverage gaps, UX
     issues) and `parallel_agents` is available, run loop-until-dry finders
     (§ Convergence and Stopping) instead of guessing a fixed count.

Record the chosen plan and a one-line rationale. The plan is a decision Forge
must be able to defend from the recorded state, not a vibe.

## The Forge Protocol

### A. ORIENT — Read State

**Session ID**: Each forge loop gets a unique session ID: `MMDD-HHMM-SLUG` where MMDD-HHMM is the current timestamp and SLUG is 2-3 words from the task (e.g., `0406-1530-djinnchat-primefix`). Generate this on the first iteration and reuse it every subsequent iteration.

State file path (substitute your session ID for `{sid}`):

- Claude Code: `.claude/forge-state.{sid}.md`
- Codex: `.codex/forge/forge-state.{sid}.md`

**On first iteration**: no state file exists yet. Generate the session ID, proceed to MEASURE, and create the state file during RECORD.

**On subsequent iterations**: read the state file matching your session ID. Never read or write a different session's state file — concurrent forge loops in the same repo are supported and must remain isolated.

- Parse baseline KPIs, targets, iteration history, current strategy
- Parse the success contract:
  - `task`: the primary requested work
  - `done_when`: explicit success override, if provided
  - `completion_checks`: concrete checks derived from task + override
- If `completion_checks` is empty, derive them before EXECUTE and persist them in forge-state
- Check `stagnation_count` — if >= 3, MUST rotate strategy
- Review lessons from previous iterations (avoid repeating failures)
- **UI detection** (first iteration only): Scan `scope` and `task` for UI signals:
  - File patterns: `*.tsx`, `*.jsx`, `*.vue`, `*.svelte`, `*.css`, `*.scss`, `*.html`
  - Task keywords: component, page, interface, design, layout, style, UI, UX, responsive, animation, frontend, theme, color, typography
  - If detected: set `ui_task: true` and `ui_quality_score: null` in forge-state
  - Check AGENT.md for a `## UI Quality Tools` section and note which commands are registered
- **Capability detection** (first iteration only): inventory what this runtime exposes
  (§ Runtime Capabilities) — subagents, a parallel/workflow orchestration primitive,
  worktree isolation, registered UI tools. Record a `capabilities` block in forge-state.
  When uncertain, treat a capability as absent and use its sequential fallback.

### B. MEASURE — Capture Current KPIs

Run your test suite with coverage enabled and parse output for:
- **coverage**: percentage from cover summary
- **speed_seconds**: total test time
- **tests**: total test count
- **failures**: failure count
- **warnings**: compiler warning count (optional, first run)
- **ui_quality_score** (UI tasks only): integer 0–100. See § UI Quality Gate. `null` until first gate runs.

**Elixir**: `mix test --cover 2>&1`
**Python**: `pytest --cov --cov-report=term 2>&1`
**JavaScript**: `npm test -- --coverage 2>&1`
**Ruby**: `bundle exec rspec 2>&1` (with SimpleCov)
**Go**: `go test -cover ./... 2>&1`

First iteration: record as **baseline** in forge-state.
Subsequent: compute deltas from previous iteration AND from baseline.

### C. EVALUATE — Fresh-Context Reality Check

**When**: iteration 1 AND every 3rd iteration thereafter (1, 4, 7, 10...).

Spawn a fresh-context audit using an agent or persona available in your environment (for example a code reviewer, security auditor, or refactorer) with:
- ONLY the scope files/modules
- Prompt: "Audit [scope]. Report findings by severity (high/medium/low). No context about KPI targets or iteration state."
- NO forge state, NO iteration context, NO KPI targets — unbiased evaluation

**UI task evaluation**: When `ui_task: true`, prefer a design quality perspective for the fresh-context pass. If `ui-quality-agent` is registered in AGENT.md `## UI Quality Tools`, use it as the evaluator. Otherwise append to the standard audit prompt: "Also evaluate: visual hierarchy and focal point, AI slop patterns (purple/blue gradients, glassmorphism, generic fonts like Inter/system-ui), accessibility violations, missing interaction states, empty/error/loading state gaps. Rate findings by severity."

Main agent reviews findings critically against its KPI targets.
Record findings count by severity in forge-state.

### Success model

Forge has two goal layers:

- **Task success** — what the requested work must make true
- **KPI guardrails** — tests, coverage, speed, quality, and no critical regressions

If the user gives only open text scope, derive concrete `completion_checks` from
that task and record them in forge-state.

If the user provides `--done-when`, treat that as the explicit override and
derive any additional clarifying `completion_checks` from it.

Do not mark Forge complete just because the KPIs improved. The task itself must
be honestly done.

### D. DECIDE — Pick Strategy

#### The Simplicity Criterion

All else being equal, simpler is better. When evaluating whether to keep a change:

- Improvement + ugly complexity → probably discard
- Improvement from DELETING code → definitely keep
- No metric change + simpler code → keep (that's a simplification win)
- Marginal gain from complexity → reject

This prevents complexity ratchet. Code removal for equivalent performance is always a win.

#### Available Strategies

| Strategy | When to use | Typical impact |
|----------|-------------|----------------|
| `component-extraction` | DRY violations, repeated patterns | Coverage + quality |
| `refactor-for-testability` | Code hard to test (private, coupled) | Coverage |
| `coverage-push` | Clear coverage gaps, uncovered modules | Coverage |
| `speed-optimization` | async:false overuse, slow fixtures, redundant DB | Speed |
| `dead-code-removal` | Unused code flagged by reality-check | Quality + coverage |
| `quality-polish` | Naming, complexity, clarity issues | Quality |
| `design-system` | Token violations, hardcoded values, duplicated UI patterns | Quality + ui_quality_score |
| `ui-quality` | ui_quality_gap largest, UI task detected | ui_quality_score |
| `simplification` | Complex code that can be made simpler | Quality (+ coverage if tests improve) |

#### Selection Logic

1. Compute **normalized KPI gap** for each target:
   - coverage_gap = (target - current) / target
   - speed_gap = (current - target) / current  (inverted — lower is better)
   - quality_gap = high_findings / 5  (scale 0..1)
   - ui_quality_gap = (threshold - ui_quality_score) / threshold  (UI tasks only; 0 if not ui_task or score is null)

2. **Largest gap** gets priority in strategy selection:
   - coverage_gap largest → `coverage-push` or `refactor-for-testability`
   - speed_gap largest → `speed-optimization`
   - quality_gap largest → `component-extraction` or `dead-code-removal`
   - ui_quality_gap largest → `ui-quality` or `design-system`

3. **High findings from reality-check** → immediate `component-extraction` or `refactor-for-testability`

4. **Stagnation** (stagnation_count >= 3):
   - Pick best historical delta strategy OR untried strategy
   - Log: "Strategy '{current}' stagnating, switching to '{new}'"
   - Reset stagnation_count

5. **Never repeat a strategy that yielded negative deltas** without changing approach

#### Plan the iteration (adaptive)

Once the strategy (or candidate strategies) are chosen, decide *how* to run this
iteration per § Adaptive Orchestration, and persist it as `iteration_plan`:

- **mode**: `sequential` or `parallel` (and, if parallel, the K dimensions/strategies to fan out)
- **verify_depth**: `light` | `review` | `adversarial` | `panel` (from the change's risk)
- **discovery**: `bounded` or `loop-until-dry` (for unknown-size find tasks)

Pick `parallel` only when the runtime supports it AND there are ≥2 independent,
non-conflicting, high-value strategies. Otherwise stay sequential — the default is
always safe. Write a one-line rationale so the choice is auditable from state.

### E. EXECUTE — ONE Coherent Improvement

Each iteration produces ONE coherent improvement. In `sequential` mode that is one
focused change. In `parallel` mode it is the **best of N candidate changes** from a
fan-out round (§ Parallel Rounds) — still one improvement accepted per iteration, just
explored in parallel first. Never batch unrelated changes into a single accepted result.

**Sequential change** — do the one thing well:

- **Structural refactoring** → use an available refactoring agent, or do the focused change directly
- **Clarity/polish** → use an available simplification/review agent, or do the focused change directly
- **Coverage gaps** → write tests + refactor for testability
- **Speed optimization** → convert sync to async tests, consolidate fixtures, reduce DB hits
- **Dead code removal** → delete unused code flagged by evaluation
- **Design system** → extract shared components, replace hardcoded values with tokens
- **UI quality** → run registered quality commands on changed files, or fix the top-scoring checklist failure (see § UI Quality Gate)
- **Simplification** → delete dead code, reduce abstractions, flatten indirection

**Parallel round** — when `iteration_plan.mode == parallel`, fan out K agents (one per
dimension/strategy) in isolation, then fan in to a single accepted improvement
(§ Parallel Rounds). Each candidate is a complete, independently-verifiable change.

Use fresh-context agents when they are available and helpful; otherwise keep the change focused and do it directly.

### F. VERIFY — Tests Must Be Green

Run tests — **must be green** before proceeding.
If red: debug and fix within this iteration. Do NOT proceed to RECORD with failures.
Re-measure with coverage to capture post-change KPIs.

**Verify at the planned depth** (`iteration_plan.verify_depth`, § Verification Depth):
green tests are the floor, not the ceiling. A risky or surprising change earns deeper
scrutiny — escalate to an adversarial pass that tries to *refute* the improvement and
its KPI claim before you accept it. If the refutation lands, treat it like a red test:
fix or revert before RECORD. Never let a fabricated or fragile "green" through.

**UI/UX quality gate** (when `ui_task: true`): After tests pass, run the UI quality check per § UI Quality Gate. Record the resulting `ui_quality_score`. A score below 50 is a critical failure — fix before RECORD, same as red tests. For interaction/flow changes, also verify the UX path end-to-end (the change does what a user needs, not just that it renders).

### G. RECORD — Update Forge State (THE Autoregressive Step)

Update the Forge state file for the current driver (using your session ID `{sid}`):

- Claude Code: `.claude/forge-state.{sid}.md`
- Codex: `.codex/forge/forge-state.{sid}.md`

1. **Append iteration entry** with:
   - Iteration number
   - KPIs before and after (with deltas), including ui_quality_score if ui_task
   - Strategy used
   - Actions taken (brief)
   - Success contract progress or refinement if it changed
   - Findings count (if evaluation ran)
   - Lesson learned

2. **Update strategy tracking**:
   - Add iteration to current strategy's history
   - Record coverage_delta and speed_delta for the strategy

3. **Stagnation detection**:
   - Coverage delta < 0.1% for 2 consecutive iterations → increment stagnation_count
   - Any improvement > 0.1% → reset stagnation_count to 0

4. **Git commit** if tests green AND any improvement:
   - Find the changelog: `CHANGELOG.md` → `HISTORY.md` → `docs/CHANGELOG.md` → create `CHANGELOG.md`
   - Add one bullet under `## [Unreleased]` (create the section if absent) describing the change in user-facing terms
   - Stage changed files (NOT forge-state, it's in .claude/), INCLUDING the changelog
   - Commit with: `forge(N): [strategy] — [brief description]`

5. **Clean revert** if tests red or KPIs regressed AND no commit:
   - Revert only the files changed in the current iteration
   - If you cannot identify that set safely, stop and leave unrelated local work untouched
   - Record what was attempted in the iteration log (even failed attempts inform future decisions)

6. **Ideas backlog** — if the iteration surfaced promising but deferred opportunities:
   - Add to the `ideas` list in forge-state frontmatter
   - On future iterations, review backlog for combination opportunities

7. **Persist project insights** — when the iteration reveals a non-obvious, project-level fact (environment quirk, architectural discovery, recurring anti-pattern), write it to the project's memory system:
   - Check CLAUDE.md for memory conventions → check `.claude/memory/` → check `docs/`
   - Fall back: append under `## Lessons` in `AGENT.md`
   - Write only facts useful to any future agent, not forge-process observations (those stay in forge-state)

8. **Compact state if long** — keep the autoregressive memory lean for long runs (§ State Compaction):
   - When the iteration log exceeds ~25 entries (or the file grows unwieldy), archive the
     oldest entries to `forge-state.{sid}.archive.md` and replace them with a short rollup
   - NEVER compact away: baseline, targets, success contract, `capabilities`, current
     `strategies_tried` deltas, open `ideas`, or lessons still in play. Compaction is
     lossless for decisions — it only sheds verbose per-iteration narration.

### H. COMPLETE — All Targets Met?

Check ALL conditions simultaneously:
- the recorded task success contract is satisfied
- coverage >= min_coverage target
- speed_seconds <= max_speed_seconds target
- failures == 0
- high_findings == 0 (from last evaluation)
- ui_task: ui_quality_score >= ui_quality_threshold (default 80)

If ALL met:
- Add a final changelog entry summarizing the full run: task completed, total iterations, key outcomes
- Commit: `forge(complete): [task summary]` including the changelog update
- Output `FORGE_COMPLETE` on its own line

If not met, also stop (gracefully, not as success) when a convergence or budget
condition trips (§ Convergence and Stopping) — no-progress across rounds, a token/cost
ceiling, or detected goal drift. On such a stop, record *why* and what remains, then
output `FORGE_COMPLETE` with an honest summary (do not claim targets were met if they
were not).

Otherwise → exit normally (stop hook re-injects prompt for next iteration)

## Stagnation Protocol

```
if stagnation_count >= 3:
  1. Log: "Strategy '{current}' stagnating after {N} low-delta iterations"
  2. Rank strategies by historical effectiveness (coverage_delta / iterations)
  3. Pick: best historical strategy OR untried strategy
  4. Reset stagnation_count to 0
  5. Record lesson: "'{old}' exhausted after iterations [X,Y,Z], switching to '{new}'"
```

### Getting Unstuck

When stagnation triggers (or when you run out of ideas within a strategy):

1. **Re-read scope files** — fresh eyes find new angles
2. **Review the ideas backlog** — deferred opportunities may be ripe now
3. **Combine near-misses** — two changes that individually didn't help may compound
4. **Try the inverse** — if adding X didn't help, try removing it (or vice versa)
5. **Think harder** — don't stop and ask. Read related code, look for patterns, try more radical changes
6. **Simplification pass** — can you delete code and maintain the same KPIs? That's a win

## Parallel Rounds

A parallel round explores several improvements at once, then accepts the single best —
the `Round N · K agents` view from the screenshot. It is an *opt-in acceleration* of a
sequential iteration, chosen adaptively in DECIDE, never a change to the keep-one
discipline. Requires `parallel_agents`; without it, fall back to trying candidates
sequentially.

### Fan-out

1. Pick K independent dimensions/strategies (e.g. `data-integrity`, `test-trust`,
   `strategy-security`, `coverage-push`). Each must be able to succeed without
   conflicting with the others.
2. Spawn one agent per dimension, **each in worktree isolation** if `worktree_isolation`
   is available (so concurrent edits never collide). Label them `rN:dimension` for legibility.
3. Each agent produces a complete, self-contained candidate change and runs tests on it.
   Agents that go red or empty-handed simply drop out of the round.

### Fan-in (judge-panel keep/discard)

4. Collect the surviving candidates. Apply binary keep/discard discipline (Karpathy):
   - **0 survivors** → nothing accepted this round; record the dry round and re-plan.
   - **1 survivor** → verify it at the planned depth, then accept.
   - **2+ survivors** → run a **judge panel**: score each candidate on the round's KPIs
     plus the Simplicity Criterion (a smaller/simpler diff at equal gain wins). Use
     `fresh_context_eval` judges if available; prefer an odd number and majority verdict.
     Keep the winner; **discard the rest cleanly** (drop their worktrees).
5. The accepted candidate then goes through F. VERIFY exactly like a sequential change.
   Only the winner is merged to the working tree and committed.

Graft, don't hoard: if a discarded candidate contained a clearly better sub-idea, note it
in `ideas` for a future iteration rather than merging two diffs at once.

## Verification Depth

Green tests are necessary, not sufficient. Forge scales scrutiny to the change's risk so
it spends verification effort where it pays off (chosen in DECIDE, applied in VERIFY).

**Risk score** (informal, per change): blast radius (files/LOC) · criticality (auth, data,
money, migrations, public API, deletion) · KPI surprise (a delta too good to be true) ·
reversibility (hard-to-undo > easy).

| Depth | When | What runs |
|-------|------|-----------|
| `light` | Trivial, low blast radius, expected KPI move | Tests + a quick self-review checklist |
| `review` | Moderate change or first touch of a module | One `fresh_context_eval` reviewer over the diff |
| `adversarial` | High/critical change, or KPI delta that looks too good | 1–N independent skeptics prompted to **refute** the change and the KPI claim — "find how this is wrong, break it, prove the metric is fake." Majority-refute ⇒ reject like a red test |
| `panel` | Competing candidates (parallel round fan-in) | Judge panel scores + keeps best (§ Parallel Rounds) |

Adversarial verification is the antidote to fake-green: a change that games coverage,
weakens an assertion, or posts an implausible speedup should be *attacked* before it is
trusted. Default skeptics to "refuted unless clearly sound." If the capability is absent,
fall back to a structured self-refutation checklist — still ask "how is this wrong?"
before accepting.

UI/UX changes verify on their own axis (§ UI Quality Gate) in addition to the above.

## Convergence and Stopping

Forge stops on success (H. COMPLETE) — but a loop that cannot reach success must still
end gracefully rather than burn forever. Track these alongside the success contract:

- **No-progress / loop-until-dry** — for bounded improvement, the existing stagnation
  counter rotates strategy at 3 low-delta iterations. For discovery tasks, run finders
  until **K consecutive dry rounds** (default 2) return nothing new, then stop — don't
  guess a fixed iteration count. A parallel round that yields 0 survivors counts as dry.
- **Budget ceiling** — respect any token/cost/time cap the runtime or user sets. When the
  remaining budget can't fund another useful round, stop and summarize what was achieved
  and what remains. Never blow a hard ceiling chasing the last KPI point.
- **Goal drift** — each iteration, re-check that the work still serves the success
  contract. If recent iterations have wandered into unrelated polish, stop and flag the
  drift rather than continuing to optimize the wrong thing.

On any of these, output `FORGE_COMPLETE` with an honest status — "converged short of
target X; remaining work: Y" — never a false claim of completion.

## State Compaction

forge-state is the autoregressive memory and must survive long runs without bloating.
When the iteration log grows past ~25 entries (or the file becomes unwieldy):

1. Move the oldest narrative entries to `forge-state.{sid}.archive.md`.
2. Replace them in-place with a 2–3 line rollup: net KPI movement, strategies exhausted,
   and any still-relevant lesson.
3. Keep verbatim in the live file: frontmatter (baseline, targets, success contract,
   `capabilities`, `iteration_plan`), current `strategies_tried` deltas, open `ideas`,
   and lessons that still guide decisions.

Compaction is lossless for *decisions* — only verbose per-iteration narration is shed.
If you cannot tell whether a fact still matters, keep it.

## UI Quality Gate

This gate activates automatically when `ui_task: true` (detected in ORIENT). It adds `ui_quality_score` (0–100) as a fourth KPI dimension alongside coverage, speed, and code quality.

### Configuration (AGENT.md)

Add this section to the project's `AGENT.md` to register available design quality tools. Omit entirely or leave commented to use the built-in fallback — forge never requires any specific tool:

```markdown
## UI Quality Tools
# Uncomment to enable richer checks (e.g. with impeccable installed):
# ui-quality-agent: impeccable:critique    ← used in EVALUATE fresh-context pass
# ui-quality-audit: impeccable:audit       ← used in VERIFY gate
# ui-quality-polish: impeccable:polish     ← used in ui-quality EXECUTE strategy
# ui-quality-threshold: 85                 ← override completion threshold (default 80)
```

### Built-in Checklist (10 points, 10 pts each)

When no tools are registered, forge runs this grep + inspection pass during VERIFY:

1. **No hardcoded hex colors** — `grep -r '#[0-9a-fA-F]\{3,6\}\b'` on source files → zero matches outside token definition files
2. **Touch targets ≥ 44px** — interactive elements (`button`, `a`, `[role=button]`) have min-height/min-width ≥ 44px or equivalent padding
3. **All inputs labeled** — every `<input>` has an associated `<label>` or `aria-label`
4. **Alt text present** — all `<img>` tags have non-empty `alt` attribute
5. **Focus states defined** — no `outline: none` or `outline: 0` without a replacement focus style
6. **Loading states present** — every async action (fetch, mutation) has a loading state in the UI
7. **Error states present** — every fetch/mutation has an error state with a user-visible message
8. **Empty states useful** — no blank-space fallbacks; empty states have context and a next-action CTA
9. **Reduced motion respected** — `prefers-reduced-motion` media query present for any animations
10. **No console.log in source** — `grep -r "console\.log"` on source (not tests) → zero matches

Score: `(passed_checks / 10) * 100`

### Scoring with Registered Tools

When `ui-quality-audit` is registered, run it and translate findings:

| Finding severity | Deduction |
|-----------------|-----------|
| Critical (blocking) | 25 pts each |
| High | 10 pts each |
| Medium | 5 pts each |
| Low | 1 pt each |

Score: `max(0, 100 - total_deductions)`

### Strategy execution (`ui-quality`)

ONE fix per iteration. Commit if score improves.

1. If `ui-quality-audit` registered: run it on files changed this iteration, identify top finding
2. If `ui-quality-polish` registered: run it on changed files
3. Otherwise: take the lowest-passing item from the built-in checklist and fix it

## Forge State File Format

Driver defaults (substitute your generated session ID for `{sid}`):

- Claude Code: `.claude/forge-state.{sid}.md`
- Codex: `.codex/forge/forge-state.{sid}.md`

```yaml
---
session_id: "0406-1530-djinnchat-primefix"  # MMDD-HHMM-SLUG, generated once on first iteration
scope: "description of scope"
success:
  mode: "task-derived"
  task: "build password reset flow"
  done_when: null
  completion_checks:
    - "users can request a reset and use the token successfully"
    - "failure paths are covered and tested"
baseline:
  coverage: 92.99
  speed_seconds: 81
  tests: 21563
  failures: 0
  ui_quality_score: null      # null if not ui_task
  measured_at: "2026-03-20T14:30:00Z"
targets:
  min_coverage: 95.0
  max_speed_seconds: 40
  quality: "moderate"
  max_iterations: 20
  ui_quality_threshold: 80    # applies when ui_task: true (configurable in AGENT.md)
ui_task: false                # set true in ORIENT if UI signals detected
capabilities:                 # detected in ORIENT (§ Runtime Capabilities)
  fresh_context_eval: true
  parallel_agents: true
  worktree_isolation: true
  workflow_orchestration: true
  ui_quality_tools: false
iteration_plan:               # set in DECIDE each iteration (§ Adaptive Orchestration)
  mode: "sequential"          # sequential | parallel
  parallel_dimensions: []     # e.g. ["data-integrity", "test-trust"] when mode: parallel
  verify_depth: "review"      # light | review | adversarial | panel
  discovery: "bounded"        # bounded | loop-until-dry
  rationale: "single dominant coverage gap; review depth (moderate blast radius)"
dry_rounds: 0                 # consecutive rounds that yielded nothing (loop-until-dry)
current_strategy: "coverage-push"
stagnation_count: 0
strategies_tried:
  - name: "coverage-push"
    iterations: [1, 2]
    coverage_delta: 0.8
    speed_delta: -5
lessons:
  - "async:true on LiveView tests saves ~3s per file"
ideas:
  - "consolidate 3 similar fixture helpers into one parameterized function"
  - "auth module has dead code paths from v1 migration"
---

## Iteration 1 — coverage-push
- Coverage: 92.99 -> 93.15 (+0.16%)
- Speed: 81s -> 79s (-2s)
- Tests: 21563 -> 21578 (+15)
- UI Quality: n/a (not ui_task)
- Actions: Added 15 tests for data_loaders.ex edge cases
- Reality-check: 2 high, 3 medium findings
- Lesson: "data_loaders has 7 identical try-rescue - extract, don't test each"
```

## Quality Levels

| Level | High findings | Medium findings |
|-------|---------------|-----------------|
| `strict` | 0 | 0 |
| `moderate` | 0 | <= 3 |
| `lax` | 0 | <= 5 |

## Critical Rules

1. **ONE coherent improvement per iteration** — resist the urge to batch. In parallel mode you may *explore* N candidates, but you accept exactly one. Small steps compound.
2. **Never skip VERIFY** — red tests mean the iteration failed. Fix before RECORD.
3. **Never fabricate KPIs** — always parse from actual test runner output.
4. **Fresh-context evaluation** — use an available isolated reviewer/audit pass to avoid anchoring bias.
5. **Lessons accumulate** — read ALL previous lessons before DECIDE. Never repeat a documented failure.
6. **Commit on green with changelog** — every improvement gets persisted to git with a `## [Unreleased]` changelog entry.
7. **State file is sacred** — it survives context compaction. Keep it accurate.
8. **Simpler is better** — code deletion at same KPIs is always a win. Don't add complexity for marginal gains.
9. **Clean revert on failure** — restore clean state before the next iteration. Never leave dirty files.
10. **Never stop to ask** — if stuck, think harder. Re-read code, review backlog, combine near-misses, try the inverse.
11. **Task success comes first** — KPIs are guardrails, not a substitute for actually finishing the requested work.
12. **Use what the runtime gives you** — detect capabilities, prefer parallel/worktree/judge-panel power when present, degrade gracefully when absent. The sequential default is always correct.
13. **Verify proportionate to risk** — cheap checks for cheap changes; adversarial refutation for risky ones or suspiciously good KPIs. Never trust a green you did not try to break.

## Support posture

- Claude Code support is first-class in this repo
- Codex support is first-class as a manual driver in this repo
- Other runtimes may reuse the protocol, but should not be described as
  officially supported unless they ship a real driver
