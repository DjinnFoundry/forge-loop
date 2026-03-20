#!/usr/bin/env bash
set -euo pipefail

CODEX_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CODEX_LIB_DIR}/../../scripts/forge-state-lib.sh"

forge_recorded_iteration() {
  local forge_state="$1"
  local recorded

  recorded="$(sed -n 's/^## Iteration \([0-9][0-9]*\).*/\1/p' "$forge_state" | tail -1)"
  if [[ -z "$recorded" ]]; then
    printf '0\n'
  else
    printf '%s\n' "$recorded"
  fi
}

forge_active_sessions() {
  local state_dir="$1"
  find "$state_dir" -maxdepth 1 -name 'loop-state.*.md' -type f -print | sort | while read -r file; do
    local active
    active="$(forge_strip_quotes "$(forge_frontmatter_value "$file" "active")")"
    if [[ "$active" == "true" ]]; then
      basename "$file" | sed 's/^loop-state\.//; s/\.md$//'
    fi
  done
}

forge_choose_session() {
  local state_dir="$1"
  local explicit_session="${2:-}"
  local active_sessions=()
  local session

  if [[ -n "$explicit_session" ]]; then
    printf '%s\n' "$explicit_session"
    return 0
  fi

  while IFS= read -r session; do
    [[ -n "$session" ]] || continue
    active_sessions+=("$session")
  done < <(forge_active_sessions "$state_dir")

  if [[ "${#active_sessions[@]}" -eq 0 ]]; then
    echo "Error: No active Codex Forge loop found in .codex/forge." >&2
    return 1
  fi

  if [[ "${#active_sessions[@]}" -gt 1 ]]; then
    echo "Error: Multiple active Codex Forge sessions found. Pass a session id explicitly." >&2
    printf '%s\n' "${active_sessions[@]}" >&2
    return 1
  fi

  printf '%s\n' "${active_sessions[0]}"
}

forge_render_prompt() {
  local template="$1"
  local session_id="$2"
  local scope="$3"
  local iteration="$4"

  sed \
    -e "s/{SESSION}/${session_id}/g" \
    -e "s/{SCOPE}/${scope//\//\\/}/g" \
    -e "s/{ITERATION}/${iteration}/g" \
    "$template"
}

forge_codex_status() {
  local state_dir="$1"
  local explicit_session="${2:-}"
  local session_id

  session_id="$(forge_choose_session "$state_dir" "$explicit_session")"

  local loop_state="${state_dir}/loop-state.${session_id}.md"
  local forge_state="${state_dir}/forge-state.${session_id}.md"

  if [[ ! -f "$loop_state" ]] || [[ ! -f "$forge_state" ]]; then
    echo "Error: Session ${session_id} is incomplete or missing state files." >&2
    return 1
  fi

  local active max_iterations scope last_prompted_iteration recorded_iteration next_iteration
  active="$(forge_strip_quotes "$(forge_frontmatter_value "$loop_state" "active")")"
  max_iterations="$(forge_strip_quotes "$(forge_frontmatter_value "$loop_state" "max_iterations")")"
  scope="$(forge_strip_quotes "$(forge_frontmatter_value "$forge_state" "scope")")"
  last_prompted_iteration="$(forge_strip_quotes "$(forge_frontmatter_value "$loop_state" "last_prompted_iteration")")"
  recorded_iteration="$(forge_recorded_iteration "$forge_state")"
  next_iteration=$((recorded_iteration + 1))

  printf 'Session: %s\n' "$session_id"
  printf 'Driver: Codex\n'
  printf 'Active: %s\n' "$active"
  printf 'Scope: %s\n' "$scope"
  printf 'Recorded iterations: %s\n' "$recorded_iteration"
  printf 'Last prompted iteration: %s\n' "${last_prompted_iteration:-0}"
  printf 'Next iteration: %s\n' "$next_iteration"
  printf 'Max iterations: %s\n' "$max_iterations"
  printf 'Forge state: .codex/forge/forge-state.%s.md\n' "$session_id"
  printf 'Loop state: .codex/forge/loop-state.%s.md\n' "$session_id"
}
