# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/DjinnFoundry/forge-loop/releases/tag/v0.1.0
