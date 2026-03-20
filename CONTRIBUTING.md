# Contributing to forge-loop

Thanks for your interest in contributing.

## How to contribute

1. Fork the repo
2. Create a feature branch (`git checkout -b my-feature`)
3. Make your changes
4. Test by running `bash tests/stop-hook.test.sh`, `bash tests/codex-driver.test.sh`, `./install.sh`, `./install-codex.sh`, and using the driver and status commands in a real project
5. Commit with a clear message
6. Push and open a PR

## What we're looking for

- **New strategies** — if you've found an effective codebase improvement pattern, add it to the strategy table in `SKILL.md`
- **New drivers** — Codex/manual/runtime adapters that reuse Forge Core without weakening the protocol
- **Language adapters** — test runner configurations for languages beyond the current set
- **Stop hook improvements** — better completion detection, error handling
- **Bug fixes** — especially around state file parsing and edge cases
- **Documentation** — clearer examples, better onboarding

## Guidelines

- Keep the protocol simple. Forge's power comes from disciplined iteration, not complexity.
- One change per PR. Small PRs get reviewed faster.
- If adding a strategy, include the "when to use" criteria and expected impact.
- Test your changes with a real forge loop before submitting.

## Architecture decisions

The skill file (`skills/forge/SKILL.md`) is the source of truth for Forge Core. The command, agent, and stop hook are the Claude Code driver. The shell entrypoints under `drivers/codex/` are the Codex driver. If you're changing protocol behavior, the skill file is where it lives.

The stop hook is designed to be compatible with Ralph Wiggum loops. Don't break that compatibility.

## Code of conduct

Be kind. Be constructive. We're all here to build better tools.
