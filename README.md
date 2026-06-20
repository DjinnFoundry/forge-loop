```
                          ·  ✦  ·  ✦  ·
                       ✦     · ⚡ ·     ✦
                         ░░▒▓████▓▒░░
                       ▒▓█▀          ▀█▓▒
                      ▓█   ◆      ◆   █▓
                      ██    ╲    ╱    ██
                      ▓█   ═══⚒═══   █▓
                       ▒▓█▄        ▄█▓▒
                         ░░▒▓████▓▒░░
                             ▓██▓
                         ╔═══╧══╧═══╗
                         ║ THE FORGE ║
                         ╚══════════╝
                        ▄▄████████████▄▄
                        ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
```

# forge-loop

**A task loop with KPI guardrails for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and Codex/manual workflows.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.10.1-green.svg)](CHANGELOG.md)

Forge is a protocol plus adapters. It takes open-text software tasks, keeps coverage/speed/quality as guardrails, records state across iterations, and runs until the work is honestly done or you stop it.

```
You: /forge "password reset flow" --done-when "users can request and complete a reset end-to-end" --coverage 90 --speed -30%

Forge: Measuring baseline... 85.2% coverage, 120s
       Success contract: password reset works end-to-end
       Strategy: coverage-push → 15 tests for edge cases
       85.8% (+0.6%), 118s (-2s) ✓
       ...iterates until task success and KPI targets are both satisfied...
```

---

## What Forge Is

Forge is for cases where plain prompting is too loose but a full agent framework is too heavy.

- Give it a task
- optionally say what "done" means
- keep tests, coverage, speed, and quality in view
- iterate with recorded state instead of re-explaining yourself every round

## Core vs Driver

### Forge Core

The portable part of the system:

- iteration protocol (Orient → Measure → Evaluate → Decide → Execute → Verify → Record → Complete)
- task-driven success contract with optional explicit `done_when`
- state format and autoregressive memory
- KPI targets (coverage, speed, quality)
- strategy selection and stagnation handling
- lessons and ideas backlog

### Claude Code Driver

The bundled runtime adapter in this repo:

- `/forge` command
- `/forge-cancel` command
- `/forge-status` command
- `agents/forge.md`
- `hooks/stop-hook.sh`
- install script that wires those assets into `~/.claude/`

### Codex Driver

The bundled Codex adapter in this repo:

- `install-codex.sh`
- `drivers/codex/bin/forge-run` — **autonomous** loop (a fresh `codex exec` per iteration)
- `drivers/codex/bin/forge-init`
- `drivers/codex/bin/forge-continue`
- `drivers/codex/bin/forge-cancel`
- `drivers/codex/bin/forge-status`
- `.forge/` state layout for per-project sessions
- shared shell state helpers reused across drivers

Both drivers are first-class. Claude gets hook-driven iteration inside one session;
Codex gets `forge-run` for hands-free iteration (a fresh `codex exec` per round, state in
`.forge/`) plus `forge-init` / `forge-continue` for step-by-step manual control.

## Support Matrix

| Environment | Status | What is actually shipped |
|-------------|--------|--------------------------|
| Claude Code | First-class | Command, agent, stop-hook driver, installer |
| Codex CLI | First-class driver | Install script, `forge-run` (autonomous via `codex exec`), `forge-init` / `forge-continue` / `forge-status` / `forge-cancel`, project-local state |
| Other agents / plain shell | Protocol-only | Reuse the protocol and state model manually |

Forge is not claiming native parity across agent runtimes. It ships two real drivers with different control surfaces.

---

## Lineage

Forge is not pretending to emerge from nowhere.

- **Ralph Wiggum** — [Geoff Huntley](https://ghuntley.com/ralph/) gave the core loop shape: fresh context, file-backed iteration, and the willingness to let simple loops do real work.
- **autoresearch** — [Andrej Karpathy](https://github.com/karpathy/autoresearch) reinforced the deletion bias, binary keep/discard discipline, and the value of tiny, explicit skills.
- **pi-autoresearch** — [Tobi Lutke and David Cortes](https://github.com/davebcn87/pi-autoresearch) pushed the pattern toward measurable software work beyond ML and made the backlog / measurement story sharper.
- **SICA** — [Self-Improving Coding Agent](https://arxiv.org/abs/2504.15228) showed that compounding improvement works better when strategy selection learns from prior evidence.
- **autoresearch-mlx** — [trevin-creator](https://github.com/trevin-creator/autoresearch-mlx) showed the loop itself can be a target of improvement, not just the code under test.

Forge’s job is not to erase those influences. It is to package them into a cleaner, more practical tool surface.

---

## How it works

### The Iteration Cycle

Each iteration executes one complete eight-phase cycle:

| Phase | What happens |
|-------|-------------|
| **A. Orient** | Read forge-state file, check task success contract + KPI trends + stagnation count; on iteration 1, detect runtime capabilities |
| **B. Measure** | Run tests with coverage, capture KPIs |
| **C. Evaluate** | Iteration 1 and every 3rd: spawn fresh-context subagent for unbiased audit |
| **D. Decide** | Pick strategy **and plan the iteration** — sequential vs. parallel fan-out, and how hard to verify |
| **E. Execute** | Apply ONE coherent improvement (a focused change, or the best of a parallel round) |
| **F. Verify** | Tests must be green; verify at the planned depth (up to adversarial refutation); re-measure KPIs |
| **G. Record** | Update forge-state with deltas + lessons (the autoregressive step); compact if long |
| **H. Complete** | Task success contract + KPI targets met, or a convergence/budget stop reached? Done. Otherwise, next iteration. |

### Success Contract

Forge is built for open-text work, not just KPI chasing.

- The task scope is the primary objective.
- `--done-when "TEXT"` is an optional explicit success override.
- If `--done-when` is omitted, Forge derives concrete completion checks from the task scope and records them in Forge state.
- Coverage, speed, and quality stay as guardrails alongside the task itself.
- Completion means both the task and the guardrails are satisfied.

### Strategies

Forge selects from named strategies based on which KPI gap is largest:

| Strategy | When | Impact |
|----------|------|--------|
| `coverage-push` | Clear coverage gaps | Coverage |
| `refactor-for-testability` | Code hard to test | Coverage |
| `component-extraction` | DRY violations, repeated patterns | Coverage + Quality |
| `speed-optimization` | Slow tests, sync overuse | Speed |
| `dead-code-removal` | Unused code flagged by evaluation | Quality + Coverage |
| `quality-polish` | Naming, complexity, clarity | Quality |
| `design-system` | Duplicated UI patterns | Quality + Coverage |
| `ui-quality` | UI task, largest UI-quality gap | UI quality score |
| `simplification` | Code that can be made simpler | Quality |

### Stagnation Detection

When coverage improves by less than 0.1% for two consecutive iterations, forge increments a stagnation counter. Once the counter reaches 3, forge automatically rotates to a different strategy — the historically most effective one, or an untried one. No manual intervention needed.

### Fresh-Context Evaluation

On iteration 1 and every 3rd thereafter, Forge runs a fresh-context audit pass. In Claude Code this is typically a subagent; in other environments it may be an isolated reviewer or manual second pass. The protocol requires fresh context, not a specific vendor primitive.

### Capability-Aware, Adaptive

Forge is single-agent and sequential **by default** — it always works that way. But the protocol describes its powers *abstractly* and each driver maps them to whatever the host actually provides. On the first iteration Forge **detects** what the runtime exposes, then adapts.

| Capability | Claude Code | Codex | Protocol-only |
|------------|:-----------:|:-----:|:-------------:|
| Fresh-context eval | ✅ | ✅ | ⚪ self-review |
| Parallel sub-agents | ✅ | 🔸 limited | ⚪ |
| Worktree isolation | ✅ | 🔸 manual | ⚪ |
| Workflow orchestration | ✅ | ⚪ | ⚪ |
| Model tiering | ✅ | 🔸 | ⚪ single model |
| UI quality tools | ✅ if installed | 🔸 | ⚪ checklist |
| Cost telemetry | ✅ | 🔸 | ⚪ wall-clock |

✅ first-class · 🔸 partial/manual · ⚪ sequential fallback

Each iteration, Forge plans **how** to run, proportionate to opportunity and risk:

- **Parallel rounds** — when several independent, high-value strategies exist and the runtime supports it, Forge fans out one worktree-isolated agent per dimension (`Round N · K agents`), then a judge panel keeps only the best change. One coherent improvement is still accepted per iteration.
- **Model tiering** — high-volume worker/finder agents run on a cheap/fast tier; judges and adversarial verifiers run on a strong tier, so parallel rounds stay economical without cheaping out where correctness is decided.
- **Verification depth** — green tests are the floor. Trivial changes get a light self-review; risky or suspiciously-good ones get an **adversarial pass** that tries to refute the change and its KPI claim before it is trusted.
- **No-cheat invariant** — going green by weakening the test contract (loosened assertions, skipped/deleted tests, lowered thresholds, mocked-away behavior) is treated as reward hacking and rejected like a red test.
- **Convergence & stopping** — beyond KPI targets, Forge stops gracefully on no-progress (loop-until-dry), a token/cost budget ceiling (informed by per-iteration telemetry), or detected goal drift — always with an honest summary, never a false claim of completion.
- **Blast-radius guard** — unattended runs stay within scope and never take destructive or irreversible git/FS/external actions; they pause for confirmation instead.
- **Cross-session lessons & state compaction** — durable lessons are pulled forward just-in-time on future runs, and long runs stay lean as old narration is archived while decisions, lessons, and the success contract are preserved.
- **Loop retrospective** — at the end of a run Forge scores *its own loop* (strategy effectiveness, wasted iterations, verification calibration, cost) and writes loop-level lessons to the ledger, so the next run starts smarter. The loop itself is a target of improvement, not just the code under it.

Every capability has a fallback. Nothing in the protocol *requires* parallelism, worktrees, or any specific tool — absent a capability, Forge degrades to its sequential equivalent and still converges.

---

## Installation

### Claude Code Driver

```bash
git clone https://github.com/DjinnFoundry/forge-loop.git
cd forge-loop
./install.sh
```

The installer symlinks the Claude Code driver assets into your `~/.claude/` directory.

**Important**: You also need to configure the stop hook that drives iteration. See [hooks/README.md](hooks/README.md) for setup instructions.

### Manual installation

```bash
mkdir -p ~/.claude/skills/forge ~/.claude/commands ~/.claude/agents ~/.claude/hooks

cp skills/forge/SKILL.md ~/.claude/skills/forge/SKILL.md
cp commands/forge.md ~/.claude/commands/forge.md
cp commands/forge-cancel.md ~/.claude/commands/forge-cancel.md
cp commands/cancel-ralph.md ~/.claude/commands/cancel-ralph.md
cp commands/forge-status.md ~/.claude/commands/forge-status.md
cp agents/forge.md ~/.claude/agents/forge.md
cp hooks/stop-hook.sh ~/.claude/hooks/stop-hook.sh

# Stop hook — see hooks/README.md for settings.json setup
```

### Codex Driver

```bash
git clone https://github.com/DjinnFoundry/forge-loop.git
cd forge-loop
./install-codex.sh
```

The Codex installer links Forge Core into `~/.codex/skills/forge/` and installs
driver entrypoints into `~/.codex/bin/`.

### Codex

**Autonomous (hands-free):**

```bash
forge-run "scope" [--done-when "TEXT"] [--coverage N] [--quality strict|moderate|lax] [--max-iterations N]
```

`forge-run` drives the whole loop: it scaffolds state, then runs one `codex exec` per
iteration (fresh context each round; state in `.forge/`) until the agent emits
`FORGE_COMPLETE`, a no-progress stall is detected, or max-iterations is reached. No
per-iteration babysitting. By default it runs `codex exec` with
`-c approval_policy=never -c sandbox_mode=workspace-write` so it never blocks on approval
prompts; override with `FORGE_CODEX_ARGS`.

In an interactive Codex session, saying **"forge it"** loads the skill, and Codex can
either run `forge-run` for you or follow the protocol directly.

**Manual (step-by-step control):**

1. Run `forge-init "scope" [--done-when "TEXT"] ...` in the target project.
2. Paste the printed prompt into Codex.
3. After each iteration, run `forge-continue` to print the next prompt.
4. Use `forge-status` to inspect the active session.
5. Use `forge-cancel` to stop the active loop while preserving Forge state.

Driver safety:

- `forge-run` stops on a no-progress stall and at max-iterations — it will not loop forever
- `forge-continue` derives the next iteration from recorded Forge state entries
- multiple active Codex sessions require an explicit session id instead of implicit selection
- `forge-status` is read-only and reports the next required iteration from Forge state

---

## Usage

### Claude Code

#### Basic

```
/forge "LiveView components" --coverage 95 --speed -20%
```

#### Open-text task with explicit success

```
/forge "password reset flow" --done-when "users can request, receive, and complete a reset end-to-end" --coverage 90 --quality strict
```

#### All options

```
/forge "SCOPE" [--done-when "TEXT"] --coverage N --speed -N% --quality strict|moderate|lax --max-iterations N
```

| Option | Default | Description |
|--------|---------|-------------|
| `SCOPE` | (required) | What to improve — quoted string |
| `--done-when "TEXT"` | task-derived | Explicit success contract. If omitted, derive completion checks from the task itself |
| `--coverage N` | baseline + 2 | Minimum coverage % target |
| `--speed -N%` | -20% | Speed reduction from baseline |
| `--quality` | moderate | strict (0 high, 0 med) / moderate (0 high, ≤3 med) / lax (0 high, ≤5 med) |
| `--max-iterations` | 20 | Safety limit |

#### Control

- **Pause**: Forge outputs `FORGE_PAUSE` when it needs your input
- **Cancel**: `/forge-cancel` stops the loop
- **Status**: `/forge-status` reports the current Claude driver session state
- **Inspect state**: `.claude/forge-state.SESSION.md` is preserved when you pause or cancel

### Protocol-Only / Manual

Use the same protocol phases and state format, but drive the loop yourself. Today that means:

- no bundled driver beyond Claude Code and Codex
- no automatic hook/runtime integration outside Claude Code
- no runtime-specific install story beyond the shipped drivers

---

## State File

Forge persists its state in driver-specific roots:

- Claude Code: `.claude/forge-state.SESSION.md`
- Codex: `.forge/forge-state.SESSION.md`

Claude’s loop driver uses `.claude/forge-loop.SESSION.local.md` as the primary
loop-state file name. Legacy `.claude/ralph-loop.SESSION.local.md` files are
still accepted for compatibility.

Other runtimes can reuse the same format in a different state root. Each iteration appends its KPIs, strategy, actions, and lessons. This is the autoregressive memory.

The example below is abbreviated — see `skills/forge/SKILL.md` (§ Forge State File Format) for the full schema, including the optional `capabilities`, `model_tiers`, `iteration_plan`, `budget`, `telemetry`, `test_contract`, `scope_paths`, and `unattended` fields.

```yaml
---
session_id: "0320-1430-api-controllers"  # MMDD-HHMM-SUFFIX (task slug, or a random token under Codex)
scope: "API controllers"
success:
  mode: "task-derived"
  task: "API controllers"
  done_when: null
  completion_checks:
    - "controller edge cases covered and passing"
    - "no controller path regresses current behavior"
baseline:
  coverage: 85.2
  speed_seconds: 120
  tests: 1250
  failures: 0
  measured_at: "2026-03-20T14:30:00Z"
targets:
  min_coverage: 90.0
  max_speed_seconds: 84
  quality: "moderate"
  max_iterations: 20
current_strategy: "component-extraction"
stagnation_count: 0
strategies_tried:
  - name: "coverage-push"
    iterations: [1, 2]
    coverage_delta: 0.8
    speed_delta: -5
lessons:
  - "async:true on controller tests saves ~3s per file"
ideas:
  - "auth module has dead code paths worth investigating"
---

## Iteration 1 — coverage-push
- Coverage: 85.2 → 85.8 (+0.6%)
- Speed: 120s → 118s (-2s)
- Tests: 1250 → 1265 (+15)
- Actions: Added 15 tests for data_loaders edge cases
- Reality-check: 2 high, 3 medium findings
- Lesson: "7 identical try-rescue blocks — extract, don't test each"
```

---

## Architecture

```
forge-loop/
├── skills/forge/SKILL.md    ← The protocol (source of truth)
├── commands/forge.md         ← Claude Code /forge command
├── commands/forge-cancel.md   ← Primary Claude stop command
├── commands/cancel-ralph.md   ← Legacy alias for compatibility
├── commands/forge-status.md  ← Shows Claude driver session status
├── drivers/codex/            ← Codex/manual driver scripts + prompt template
│   ├── bin/
│   │   ├── forge-init
│   │   ├── forge-continue
│   │   ├── forge-cancel
│   │   └── forge-status
│   ├── lib.sh
│   ├── prompt.md
│   └── README.md
├── agents/forge.md           ← Subagent for spawning forge on subsystems
├── hooks/                    ← Iteration engine
│   ├── README.md             ← Hook setup instructions
│   └── stop-hook.sh          ← Stop hook script
├── install.sh                ← Installer script
├── install-codex.sh          ← Codex driver installer
├── scripts/forge-state-lib.sh ← Shared shell state helpers
├── tests/
│   ├── stop-hook.test.sh
│   └── codex-driver.test.sh
├── CHANGELOG.md
├── CONTRIBUTING.md
└── README.md
```

The runtime layout is intentionally asymmetric: the protocol is portable, while drivers map that protocol to their runtime's real affordances. The Claude driver uses a stop hook and loop-state files. The Codex driver uses explicit shell entrypoints and project-local state files. Both preserve the same Forge Core semantics.

---

## Design Principles

Distilled from Ralph, autoresearch, pi-autoresearch, SICA, and a dozen related loops:

1. **Loops are simple. The magic is in the loop.** The universal pattern is: Modify, Measure, Compare, Keep/Discard, Record, Repeat. Everything else is details.
2. **Simpler is better.** Code deletion at same KPIs is always a win. Don't add complexity for marginal gains.
3. **Autonomy scales when you constrain scope, clarify success, and mechanize verification.** Tests aren't just QA — they're the rails the loop runs on.
4. **Binary keep/discard.** Improved? Keep. Didn't? Revert. No gray area, no partial credit.
5. **State survives context.** The forge-state file is the autoregressive memory. It survives context compaction, agent restarts, and session swaps.
6. **Fresh eyes beat anchored ones.** Subagents with no iteration context prevent "the numbers look fine" bias.
7. **Think harder, don't stop.** When stuck: re-read code, review backlog, combine near-misses, try the inverse, try simplification. Never pause to ask.
8. **Each improvement should make future improvements easier.** (Addy Osmani)

---

## Why not just raw loops?

| Aspect | Raw loop | Forge |
|--------|----------|-------|
| KPI tracking | Ad-hoc | Structured state file with deltas + trends |
| Strategy | Single prompt | 9 named strategies, auto-rotation on stagnation |
| Evaluation | Self-evaluation (anchoring bias) | Fresh-context audits on iteration 1 and every 3rd |
| Memory | Context window only | Persistent state file survives compaction |
| Completion | Manual / hope | Exact completion marker after task success plus protocol checks |
| Lessons | Lost between iterations | Accumulated, inform strategy selection |
| Stagnation | Repeats same approach | Detects + rotates after low-delta iterations |
| Portability | Rebuild per runtime | Portable protocol, Claude and Codex drivers bundled |

---

## Claims We Are Willing To Make

- Forge packages proven loop patterns into a reusable protocol with first-class Claude Code and Codex/manual drivers.
- Forge improves repeatability versus ad-hoc prompting when you care about task success, KPI guardrails, iteration memory, and strategy rotation.
- Forge does **not** yet provide universal runtime adapter parity beyond the shipped drivers.
- Forge is more preconfigured than raw hooks. It is not a new primitive.

## Requirements

### Claude Code Driver

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `jq` (for the stop hook)
- A project with a test suite that reports coverage

### Codex Driver

- Codex CLI
- `jq`
- A project with a test suite that reports coverage
- `~/.codex/bin` on your `PATH` if you want driver commands globally available

### Protocol-Only Reuse

- Any agent/runtime that can follow the Forge protocol manually
- Some place to persist Forge state between iterations
- A project with a measurable test/quality loop

## Adapting for other languages

The skill includes test runner examples for multiple languages (Elixir, Python, JavaScript, Ruby, Go). To adapt:

1. Edit `skills/forge/SKILL.md` — update the MEASURE phase for your test runner
2. Update the coverage/speed parsing for your output format
3. Everything else (strategies, stagnation, state format) is language-agnostic

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
