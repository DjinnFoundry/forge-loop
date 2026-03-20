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
[![Version](https://img.shields.io/badge/version-0.1.0-green.svg)](CHANGELOG.md)

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

- **Ralph Wiggum** — [Geoff Huntley's](https://ghuntley.com/ralph/) foundational work on autonomous AI development loops. "Deterministically bad in an undeterministic world, but eventually consistent." Forge is our implementation of the Ralph loop pattern with structured KPI tracking and strategy rotation.
- **Andrej Karpathy** — The autoregressive mindset: each output becomes the next input. Karpathy's work on autoregressive models and his advocacy for [vibe coding](https://x.com/karpathy/status/1886192184808149383) informed forge's core loop design — each iteration's KPIs, findings, and lessons become the next iteration's decision context.
- **Tobi Lutke** — His emphasis on tight feedback loops, continuous iteration, and measuring everything resonated deeply with our approach to autonomous improvement.
- **SICA** (Self-Improving Coding Agent, [ICLR 2025 SSI-FM Workshop](https://openreview.net/forum?id=gXVQdNXqoc)) — Demonstrated that compounding iterations (17% to 53% SWE-Bench) work when the agent can select strategies based on accumulated evidence.

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
