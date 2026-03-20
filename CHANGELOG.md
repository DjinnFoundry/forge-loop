# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-03-20

### Added
- Optional explicit `--done-when "TEXT"` success contract for Forge task scopes

### Changed
- Forge now treats open-text task completion as the primary objective and KPI targets as guardrails
- Codex driver status and prompt rendering now surface success mode and `done_when` text
- README and driver docs now describe task-derived completion checks when no explicit success override is provided

## [0.4.2] - 2026-03-20

### Added
- `forge-status` surfaces for both Claude Code and Codex/manual drivers
- Shared shell state helpers in `scripts/forge-state-lib.sh`

### Fixed
- Codex driver tests now cover malformed state and max-iteration edge cases

### Changed
- Claude stop hook and Codex driver now share the same frontmatter parsing helpers

## [0.4.1] - 2026-03-20

### Fixed
- Codex driver now derives the next iteration from recorded Forge state instead of blindly incrementing loop metadata
- Codex driver now fails closed when multiple active sessions exist and no explicit session id is provided

### Changed
- Extracted shared Codex driver state helpers into `drivers/codex/lib.sh`
- Expanded Codex driver regression tests to cover repeated continue calls and multi-session ambiguity

## [0.4.0] - 2026-03-20

### Added
- First-class Codex/manual driver with `forge-init`, `forge-continue`, and `forge-cancel`
- `install-codex.sh` for linking Forge Core and Codex driver entrypoints into `~/.codex`
- Codex driver docs, prompt template, and regression tests

### Changed
- README and Forge Core docs now describe two shipped drivers instead of one
- Support matrix now treats Codex as a bundled manual driver rather than protocol-only reuse
- State docs now describe both `.claude/` and `.codex/forge/` driver roots

## [0.3.0] - 2026-03-20

### Changed
- Reframed Forge as `Forge Core` plus a first-class Claude Code driver instead of implying universal runtime support
- Added an explicit support matrix covering Claude Code, Codex/manual protocol reuse, and other runtimes
- Clarified claims across README, skill, hook docs, and agent surfaces so portability and support are described honestly

### Added
- Core-vs-driver architecture explanation in the protocol and README
- Manual/protocol-only usage guidance for Codex and other non-Claude runtimes
- Contribution guidance for new runtime drivers

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

[0.5.0]: https://github.com/DjinnFoundry/forge-loop/releases/tag/v0.5.0
[0.4.2]: https://github.com/DjinnFoundry/forge-loop/releases/tag/v0.4.2
[0.4.1]: https://github.com/DjinnFoundry/forge-loop/releases/tag/v0.4.1
[0.4.0]: https://github.com/DjinnFoundry/forge-loop/releases/tag/v0.4.0
[0.3.0]: https://github.com/DjinnFoundry/forge-loop/releases/tag/v0.3.0
[0.2.1]: https://github.com/DjinnFoundry/forge-loop/releases/tag/v0.2.1
[0.2.0]: https://github.com/DjinnFoundry/forge-loop/releases/tag/v0.2.0
[0.1.0]: https://github.com/DjinnFoundry/forge-loop/releases/tag/v0.1.0
