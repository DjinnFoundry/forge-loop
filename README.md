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

**Autoregressive codebase improvement for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.2.0-green.svg)](CHANGELOG.md)

A structured, KPI-driven, self-correcting loop that tracks metrics (coverage, speed, quality), evaluates with fresh-context subagents, rotates strategies when stagnating, and knows when it's done.

```
You: /forge "API controllers" --coverage 90 --speed -30%

Forge: Measuring baseline... 85.2% coverage, 120s
       Strategy: coverage-push → 15 tests for edge cases
       85.8% (+0.6%), 118s (-2s) ✓
       ...iterates until all targets met simultaneously...
```

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
| **A. Orient** | Read forge-state file, check position + trends + stagnation count |
| **B. Measure** | Run tests with coverage, capture KPIs |
| **C. Evaluate** | Every 3rd iteration: spawn fresh-context subagent for unbiased audit |
| **D. Decide** | Pick strategy from KPI gaps + findings + lessons |
| **E. Execute** | Apply ONE focused transformation |
| **F. Verify** | Tests must be green, re-measure KPIs |
| **G. Record** | Update forge-state with deltas + lessons (the autoregressive step) |
| **H. Complete** | All targets met simultaneously? Done. Otherwise, next iteration. |

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

Every 3rd iteration, forge spawns a subagent that audits the scope with zero knowledge of KPI targets or iteration history. This prevents anchoring bias — the agent evaluating the code has no stake in the numbers looking good.

---

## Installation

```bash
git clone https://github.com/DjinnFoundry/forge-loop.git
cd forge-loop
./install.sh
```

The installer symlinks the skill, command, and agent files into your `~/.claude/` directory.

**Important**: You also need to configure the stop hook that drives iteration. See [hooks/README.md](hooks/README.md) for setup instructions. If you already have the Ralph Wiggum stop hook configured, forge works with it automatically.

### Manual installation

```bash
mkdir -p ~/.claude/skills/forge ~/.claude/commands ~/.claude/agents

cp skills/forge/SKILL.md ~/.claude/skills/forge/SKILL.md
cp commands/forge.md ~/.claude/commands/forge.md
cp agents/forge.md ~/.claude/agents/forge.md

# Stop hook — see hooks/README.md for settings.json setup
```

---

## Usage

### Basic

```
/forge "LiveView components" --coverage 95 --speed -20%
```

### All options

```
/forge "SCOPE" --coverage N --speed -N% --quality strict|moderate|lax --max-iterations N
```

| Option | Default | Description |
|--------|---------|-------------|
| `SCOPE` | (required) | What to improve — quoted string |
| `--coverage N` | baseline + 2 | Minimum coverage % target |
| `--speed -N%` | -20% | Speed reduction from baseline |
| `--quality` | moderate | strict (0 high, 0 med) / moderate (0 high, ≤3 med) / lax (0 high, ≤5 med) |
| `--max-iterations` | 20 | Safety limit |

### Control

- **Pause**: Forge outputs `RALPH_PAUSE` when it needs your input
- **Cancel**: `/cancel-ralph` stops the loop
- **Resume**: Start a new session — it picks up the forge-state file

---

## State File

Forge persists its state in `.claude/forge-state.SESSION.md` — a YAML frontmatter + markdown log that survives context compaction. Each iteration appends its KPIs, strategy, actions, and lessons. This is the autoregressive memory.

```yaml
---
session_id: "0320-1430-a3b2"
scope: "API controllers"
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
├── agents/forge.md           ← Subagent for spawning forge on subsystems
├── hooks/                    ← Iteration engine
│   ├── README.md             ← Hook setup instructions
│   └── stop-hook.sh          ← Stop hook script
├── install.sh                ← Installer script
├── CHANGELOG.md
├── CONTRIBUTING.md
└── README.md
```

The iteration engine uses the Ralph loop pattern: each time the Claude Code session tries to exit, the stop hook re-injects the forge prompt. The forge state file provides continuity across iterations and context compactions.

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
| Strategy | Single prompt | 7 named strategies, auto-rotation on stagnation |
| Evaluation | Self-evaluation (anchoring bias) | Fresh-context subagents every 3 iterations |
| Memory | Context window only | Persistent state file survives compaction |
| Completion | Manual / hope | Simultaneous multi-KPI gate |
| Lessons | Lost between iterations | Accumulated, inform strategy selection |
| Stagnation | Repeats same approach | Detects + rotates after low-delta iterations |

---

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `jq` (for the stop hook)
- A project with a test suite that reports coverage

## Adapting for other languages

The skill includes test runner examples for multiple languages (Elixir, Python, JavaScript, Ruby, Go). To adapt:

1. Edit `skills/forge/SKILL.md` — update the MEASURE phase for your test runner
2. Update the coverage/speed parsing for your output format
3. Everything else (strategies, stagnation, state format) is language-agnostic

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
