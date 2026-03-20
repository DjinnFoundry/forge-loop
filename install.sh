#!/usr/bin/env bash
set -euo pipefail

# forge-loop installer
# Symlinks skill, command, and agent into ~/.claude/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

echo "Installing forge-loop Claude Code driver..."

# Ensure all target directories exist
mkdir -p "${CLAUDE_DIR}/skills/forge"
mkdir -p "${CLAUDE_DIR}/commands"
mkdir -p "${CLAUDE_DIR}/agents"
mkdir -p "${CLAUDE_DIR}/hooks"

# Verify source files exist
for src in "skills/forge/SKILL.md" "commands/forge.md" "commands/forge-cancel.md" "commands/cancel-ralph.md" "commands/forge-status.md" "agents/forge.md" "hooks/stop-hook.sh" "scripts/forge-state-lib.sh"; do
  if [[ ! -f "${SCRIPT_DIR}/${src}" ]]; then
    echo "Error: Source file not found: ${SCRIPT_DIR}/${src}" >&2
    exit 1
  fi
done

# Skill
if [ -L "${CLAUDE_DIR}/skills/forge/SKILL.md" ] || [ -f "${CLAUDE_DIR}/skills/forge/SKILL.md" ]; then
  rm -f "${CLAUDE_DIR}/skills/forge/SKILL.md"
fi
ln -s "${SCRIPT_DIR}/skills/forge/SKILL.md" "${CLAUDE_DIR}/skills/forge/SKILL.md"
echo "  Linked skills/forge/SKILL.md"

# Command
if [ -L "${CLAUDE_DIR}/commands/forge.md" ] || [ -f "${CLAUDE_DIR}/commands/forge.md" ]; then
  rm -f "${CLAUDE_DIR}/commands/forge.md"
fi
ln -s "${SCRIPT_DIR}/commands/forge.md" "${CLAUDE_DIR}/commands/forge.md"
echo "  Linked commands/forge.md"

if [ -L "${CLAUDE_DIR}/commands/forge-cancel.md" ] || [ -f "${CLAUDE_DIR}/commands/forge-cancel.md" ]; then
  rm -f "${CLAUDE_DIR}/commands/forge-cancel.md"
fi
ln -s "${SCRIPT_DIR}/commands/forge-cancel.md" "${CLAUDE_DIR}/commands/forge-cancel.md"
echo "  Linked commands/forge-cancel.md"

if [ -L "${CLAUDE_DIR}/commands/cancel-ralph.md" ] || [ -f "${CLAUDE_DIR}/commands/cancel-ralph.md" ]; then
  rm -f "${CLAUDE_DIR}/commands/cancel-ralph.md"
fi
ln -s "${SCRIPT_DIR}/commands/cancel-ralph.md" "${CLAUDE_DIR}/commands/cancel-ralph.md"
echo "  Linked commands/cancel-ralph.md (legacy alias)"

if [ -L "${CLAUDE_DIR}/commands/forge-status.md" ] || [ -f "${CLAUDE_DIR}/commands/forge-status.md" ]; then
  rm -f "${CLAUDE_DIR}/commands/forge-status.md"
fi
ln -s "${SCRIPT_DIR}/commands/forge-status.md" "${CLAUDE_DIR}/commands/forge-status.md"
echo "  Linked commands/forge-status.md"

# Agent
if [ -L "${CLAUDE_DIR}/agents/forge.md" ] || [ -f "${CLAUDE_DIR}/agents/forge.md" ]; then
  rm -f "${CLAUDE_DIR}/agents/forge.md"
fi
ln -s "${SCRIPT_DIR}/agents/forge.md" "${CLAUDE_DIR}/agents/forge.md"
echo "  Linked agents/forge.md"

if [ -L "${CLAUDE_DIR}/hooks/stop-hook.sh" ] || [ -f "${CLAUDE_DIR}/hooks/stop-hook.sh" ]; then
  rm -f "${CLAUDE_DIR}/hooks/stop-hook.sh"
fi
ln -s "${SCRIPT_DIR}/hooks/stop-hook.sh" "${CLAUDE_DIR}/hooks/stop-hook.sh"
echo "  Linked hooks/stop-hook.sh"

echo ""
echo "Done. forge-loop Claude Code driver installed."
echo ""
echo "Usage: /forge \"scope\" --coverage N --speed -N%"
echo ""
echo "IMPORTANT: Point your Claude Code Stop hook at ~/.claude/hooks/stop-hook.sh."
echo "See hooks/README.md for setup details."
