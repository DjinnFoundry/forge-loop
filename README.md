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

**Forge Core with first-class drivers for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and Codex/manual workflows.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.5.1-green.svg)](CHANGELOG.md)

Forge is a protocol plus adapters. The protocol defines task success, KPI guardrails, state, strategy rotation, evaluation cadence, and completion rules. The bundled drivers make that protocol run inside Claude Code and Codex/manual workflows.

```
You: /forge "password reset flow" --done-when "users can request and complete a reset end-to-end" --coverage 90 --speed -30%

Forge: Measuring baseline... 85.2% coverage, 120s
       Success contract: password reset works end-to-end
       Strategy: coverage-push → 15 tests for edge cases
       85.8% (+0.6%), 118s (-2s) ✓
       ...iterates until task success and KPI targets are both satisfied...
```

---

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
- `/cancel-ralph` command
- `/forge-status` command
- `agents/forge.md`
- `hooks/stop-hook.sh`
- install script that wires those assets into `~/.claude/`

### Codex Driver

The bundled Codex/manual adapter in this repo:

- `install-codex.sh`
- `drivers/codex/bin/forge-init`
- `drivers/codex/bin/forge-continue`
- `drivers/codex/bin/forge-cancel`
- `drivers/codex/bin/forge-status`
- `.codex/forge/` state layout for per-project sessions
- shared shell state helpers reused across drivers

Both drivers are first-class in `v0.5.1`. The difference is automation depth:
Claude gets hook-driven iteration; Codex gets manual driver scripts that print
the next prompt and manage session state.

## Support Matrix

| Environment | Status | What is actually shipped |
|-------------|--------|--------------------------|
| Claude Code | First-class | Command, agent, stop-hook driver, installer |
| Codex CLI | First-class manual driver | Install script, `forge-init`, `forge-continue`, `forge-cancel`, project-local state |
| Other agents / plain shell | Protocol-only | Reuse the protocol and state model manually |

Forge is not claiming native parity across agent runtimes. `v0.5.1` ships two real drivers with different control surfaces.

---

## Standing on the shoulders of

- **Ralph Wiggum** — [Geoff Huntley's](https://ghuntley.com/ralph/) foundational work on autonomous AI development loops. Fresh context per iteration, files as message bus, backpressure as the quality mechanism. "Deterministically bad in an undeterministic world, but eventually consistent." Forge is our implementation of the Ralph loop pattern with structured KPI tracking and strategy rotation.
- **Andrej Karpathy** — [autoresearch](https://github.com/karpathy/autoresearch): 700 experiments in 2 days, ~20 additive improvements, 11% efficiency gain. The simplicity criterion ("code deletion for equivalent performance is always a win"), binary keep/discard with git reset, `program.md` as a "super lightweight skill", and "NEVER STOP" philosophy shaped forge's core design.
- **Tobi Lutke & David Cortes** — [pi-autoresearch](https://github.com/davebcn87/pi-autoresearch): generalized the autoresearch pattern beyond ML to any software optimization. Noise estimation via MAD-based confidence scoring, backpressure checks (correctness gates separate from metric timing), persistent state via JSONL, and the ideas backlog pattern. Lutke's [context engineering](https://x.com/tobi/status/1909251946235437514) philosophy — "the art of providing all the context for the task to be plausibly solvable by the LLM" — is what makes loops work. 120 experiments on Shopify's Liquid yielded 53% faster parse+render.
- **SICA** (Self-Improving Coding Agent, [arxiv.org/abs/2504.15228](https://arxiv.org/abs/2504.15228)) — Demonstrated that compounding iterations (17% to 53% SWE-Bench) work when the agent selects the best strategy from an archive of accumulated evidence.
- **autoresearch-mlx** — [trevin-creator](https://github.com/trevin-creator/autoresearch-mlx): not just a port but genuine architectural innovation. The agent autonomously discovered that depth=4 beats depth=8 under time-budget constraints. Nobody improved the loop itself across 4 forks — the largest untapped opportunity that forge addresses.

---

## How it works

### The Iteration Cycle

Each iteration executes one complete eight-phase cycle:

| Phase | What happens |
|-------|-------------|
| **A. Orient** | Read forge-state file, check task success contract + KPI trends + stagnation count |
| **B. Measure** | Run tests with coverage, capture KPIs |
| **C. Evaluate** | Every 3rd iteration: spawn fresh-context subagent for unbiased audit |
| **D. Decide** | Pick strategy from KPI gaps + findings + lessons |
| **E. Execute** | Apply ONE focused transformation |
| **F. Verify** | Tests must be green, re-measure KPIs |
| **G. Record** | Update forge-state with deltas + lessons (the autoregressive step) |
| **H. Complete** | Task success contract satisfied and KPI targets met? Done. Otherwise, next iteration. |

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
| `simplification` | Code that can be made simpler | Quality |

### Stagnation Detection

When coverage improves by less than 0.1% for two consecutive iterations, forge increments a stagnation counter. Once the counter reaches 3, forge automatically rotates to a different strategy — the historically most effective one, or an untried one. No manual intervention needed.

### Fresh-Context Evaluation

Every 3rd iteration, Forge runs a fresh-context audit pass. In Claude Code this is typically a subagent; in other environments it may be an isolated reviewer or manual second pass. The protocol requires fresh context, not a specific vendor primitive.

---

## Installation

### Claude Code Driver

```bash
git clone https://github.com/DjinnFoundry/forge-loop.git
cd forge-loop
./install.sh
```

The installer symlinks the Claude Code driver assets into your `~/.claude/` directory.

**Important**: You also need to configure the stop hook that drives iteration. See [hooks/README.md](hooks/README.md) for setup instructions. If you already have the Ralph Wiggum stop hook configured, forge works with it automatically.

### Manual installation

```bash
mkdir -p ~/.claude/skills/forge ~/.claude/commands ~/.claude/agents

cp skills/forge/SKILL.md ~/.claude/skills/forge/SKILL.md
cp commands/forge.md ~/.claude/commands/forge.md
cp commands/cancel-ralph.md ~/.claude/commands/cancel-ralph.md
cp agents/forge.md ~/.claude/agents/forge.md

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

### Codex / Manual Use

Codex support is manual by design, but it is now a real shipped driver.

Typical flow:

1. Run `forge-init "scope" [--done-when "TEXT"] ...` in the target project.
2. Paste the printed prompt into Codex.
3. After each iteration, run `forge-continue` to print the next prompt.
4. Use `forge-status` to inspect the active session.
5. Use `forge-cancel` to stop the active loop while preserving Forge state.

This is a first-class manual driver, not a hook-based runtime integration.

Driver safety:

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

- **Pause**: Forge outputs `RALPH_PAUSE` when it needs your input
- **Cancel**: `/cancel-ralph` stops the loop
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
- Codex: `.codex/forge/forge-state.SESSION.md`

Other runtimes can reuse the same format in a different state root. Each iteration appends its KPIs, strategy, actions, and lessons. This is the autoregressive memory.

```yaml
---
session_id: "0320-1430-a3b2"
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
├── commands/cancel-ralph.md  ← Stops the active loop in this project
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

The runtime layout is intentionally asymmetric: the protocol is portable, while drivers map that protocol to their runtime's real affordances. The Claude driver uses the Ralph loop pattern and a stop hook. The Codex driver uses explicit shell entrypoints and project-local state files. Both preserve the same Forge Core semantics.

---

## Design Principles

Distilled from studying autoresearch, Ralph Wiggum, pi-autoresearch, SICA, and a dozen forks:

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
| Strategy | Single prompt | 8 named strategies, auto-rotation on stagnation |
| Evaluation | Self-evaluation (anchoring bias) | Fresh-context audits every 3 iterations |
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
