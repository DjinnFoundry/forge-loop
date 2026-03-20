# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2026-03-20

### Added
- `/cancel-ralph` command for stopping the active loop in the current project without deleting forge-state
- `tests/stop-hook.test.sh` regression coverage for completion markers, pause markers, paused state handling, and completion promises

### Fixed
- Stop hook now requires exact control markers on their own line instead of matching substrings inside normal prose
- Paused loops are ignored until they are explicitly resumed, instead of being silently reclaimed by the next session
- Installer now links the `/cancel-ralph` command alongside `/forge`

### Changed
- Forge docs and skill instructions now describe exact control-marker semantics instead of implying the hook validates KPI targets itself
- Fresh-context audit guidance now refers only to agents/personas available in the caller's environment
- Failure recovery guidance now forbids whole-worktree reverts and limits cleanup to files changed in the current iteration

## [0.2.0] - 2026-03-20

### Added
- **Simplicity criterion** in DECIDE phase — code deletion at same KPIs is always a win; marginal gains from complexity are rejected
- **`simplification` strategy** — dedicated strategy for reducing code complexity
- **Clean revert on failure** — explicit `git checkout` to restore clean state between iterations
- **Ideas backlog** in forge-state — captures deferred opportunities for future iterations
- **Getting Unstuck protocol** — re-read scope, review backlog, combine near-misses, try the inverse, simplification pass
- **"Never stop to ask" rule** — agent thinks harder instead of pausing for user input
- **Design Principles section** in README — 8 principles distilled from studying autoresearch, Ralph Wiggum, pi-autoresearch, SICA, and forks
- **Deep research** — 6 research documents in `.research/` analyzing primary sources

### Changed
- Expanded credits with proper links and specific contributions from each influence
- Strategy table now includes `simplification` (8 strategies total)
- Critical Rules expanded from 7 to 10

## [0.1.0] - 2026-03-20

### Added
- The Forge Protocol — eight-phase iteration cycle (Orient, Measure, Evaluate, Decide, Execute, Verify, Record, Complete)
- 7 named strategies with automatic selection based on normalized KPI gaps
- Stagnation detection and automatic strategy rotation after 3 low-delta iterations
- Fresh-context evaluation via subagents every 3rd iteration (prevents anchoring bias)
- Autoregressive state file (`.claude/forge-state.SESSION.md`) that persists KPIs, strategies, and lessons across iterations
- Stop hook for iteration engine (compatible with Ralph Wiggum loops)
- `/forge` command with `--coverage`, `--speed`, `--quality`, and `--max-iterations` options
- Forge agent for spawning as a subagent on subsystems
- Installer script with symlink-based setup
- Multi-language support in MEASURE phase (Elixir, Python, JavaScript, Ruby, Go)
- Simultaneous multi-KPI completion gate

[0.2.1]: https://github.com/DjinnFoundry/forge-loop/releases/tag/v0.2.1
[0.2.0]: https://github.com/DjinnFoundry/forge-loop/releases/tag/v0.2.0
[0.1.0]: https://github.com/DjinnFoundry/forge-loop/releases/tag/v0.1.0
