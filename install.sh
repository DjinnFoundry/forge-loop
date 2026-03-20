#!/usr/bin/env bash
set -euo pipefail

# forge-loop installer
# Symlinks skill, command, and agent into ~/.claude/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

echo "Installing forge-loop..."

# Ensure all target directories exist
mkdir -p "${CLAUDE_DIR}/skills/forge"
mkdir -p "${CLAUDE_DIR}/commands"
mkdir -p "${CLAUDE_DIR}/agents"

# Verify source files exist
for src in "skills/forge/SKILL.md" "commands/forge.md" "commands/cancel-ralph.md" "agents/forge.md"; do
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

if [ -L "${CLAUDE_DIR}/commands/cancel-ralph.md" ] || [ -f "${CLAUDE_DIR}/commands/cancel-ralph.md" ]; then
  rm -f "${CLAUDE_DIR}/commands/cancel-ralph.md"
fi
ln -s "${SCRIPT_DIR}/commands/cancel-ralph.md" "${CLAUDE_DIR}/commands/cancel-ralph.md"
echo "  Linked commands/cancel-ralph.md"

# Agent
if [ -L "${CLAUDE_DIR}/agents/forge.md" ] || [ -f "${CLAUDE_DIR}/agents/forge.md" ]; then
  rm -f "${CLAUDE_DIR}/agents/forge.md"
fi
ln -s "${SCRIPT_DIR}/agents/forge.md" "${CLAUDE_DIR}/agents/forge.md"
echo "  Linked agents/forge.md"

echo ""
echo "Done. forge-loop installed."
echo ""
echo "Usage: /forge \"scope\" --coverage N --speed -N%"
echo ""
echo "IMPORTANT: You need the stop hook for iteration to work."
echo "See hooks/README.md for setup, or if you already have the"
echo "Ralph Wiggum stop hook configured, forge works automatically."
