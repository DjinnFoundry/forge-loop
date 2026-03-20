#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_DIR="${HOME}/.codex"
CODEX_SKILL_DIR="${CODEX_DIR}/skills/forge"
CODEX_BIN_DIR="${CODEX_DIR}/bin"

echo "Installing forge-loop Codex driver..."

mkdir -p "$CODEX_SKILL_DIR"
mkdir -p "$CODEX_BIN_DIR"

for src in \
  "skills/forge/SKILL.md" \
  "drivers/codex/lib.sh" \
  "drivers/codex/README.md" \
  "drivers/codex/prompt.md" \
  "drivers/codex/bin/forge-init" \
  "drivers/codex/bin/forge-continue" \
  "drivers/codex/bin/forge-cancel" \
  "drivers/codex/bin/forge-status"
do
  if [[ ! -f "${SCRIPT_DIR}/${src}" ]]; then
    echo "Error: Source file not found: ${SCRIPT_DIR}/${src}" >&2
    exit 1
  fi
done

for target in \
  "${CODEX_SKILL_DIR}/SKILL.md" \
  "${CODEX_BIN_DIR}/forge-init" \
  "${CODEX_BIN_DIR}/forge-continue" \
  "${CODEX_BIN_DIR}/forge-cancel" \
  "${CODEX_BIN_DIR}/forge-status"
do
  if [[ -L "$target" ]] || [[ -f "$target" ]]; then
    rm -f "$target"
  fi
done

ln -s "${SCRIPT_DIR}/skills/forge/SKILL.md" "${CODEX_SKILL_DIR}/SKILL.md"
ln -s "${SCRIPT_DIR}/drivers/codex/bin/forge-init" "${CODEX_BIN_DIR}/forge-init"
ln -s "${SCRIPT_DIR}/drivers/codex/bin/forge-continue" "${CODEX_BIN_DIR}/forge-continue"
ln -s "${SCRIPT_DIR}/drivers/codex/bin/forge-cancel" "${CODEX_BIN_DIR}/forge-cancel"
ln -s "${SCRIPT_DIR}/drivers/codex/bin/forge-status" "${CODEX_BIN_DIR}/forge-status"

chmod +x \
  "${SCRIPT_DIR}/drivers/codex/lib.sh" \
  "${SCRIPT_DIR}/drivers/codex/bin/forge-init" \
  "${SCRIPT_DIR}/drivers/codex/bin/forge-continue" \
  "${SCRIPT_DIR}/drivers/codex/bin/forge-cancel" \
  "${SCRIPT_DIR}/drivers/codex/bin/forge-status"

echo "  Linked skills/forge/SKILL.md"
echo "  Linked drivers/codex/bin/forge-init"
echo "  Linked drivers/codex/bin/forge-continue"
echo "  Linked drivers/codex/bin/forge-cancel"
echo "  Linked drivers/codex/bin/forge-status"
echo ""
echo "Done. forge-loop Codex driver installed."
echo ""
echo "Add ~/.codex/bin to PATH if it is not already available."
echo "Usage:"
echo "  forge-init \"scope\" --coverage 90 --speed -20%"
echo "  forge-continue"
echo "  forge-cancel"
echo "  forge-status"
