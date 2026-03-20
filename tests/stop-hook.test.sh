#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_PATH="${ROOT_DIR}/hooks/stop-hook.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$expected" != "$actual" ]]; then
    fail "${message}: expected '${expected}', got '${actual}'"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "$haystack" != *"$needle"* ]]; then
    fail "${message}: missing '${needle}'"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "$haystack" == *"$needle"* ]]; then
    fail "${message}: unexpectedly found '${needle}'"
  fi
}

state_field() {
  local repo_dir="$1"
  local field="$2"

  sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "${repo_dir}/.claude/ralph-loop.test.local.md" \
    | awk -F: -v field="$field" '$1 == field { sub(/^[^:]+:[[:space:]]*/, "", $0); gsub(/^"|"$/, "", $0); print; exit }'
}

write_state() {
  local repo_dir="$1"
  local active="$2"
  local iteration="$3"
  local completion_promise="$4"

  cat > "${repo_dir}/.claude/ralph-loop.test.local.md" <<EOF
---
active: ${active}
session_id: "test"
session_transcript: null
iteration: ${iteration}
max_iterations: 20
completion_promise: ${completion_promise}
started_at: "2026-03-20T14:30:00Z"
---

PROMPT BODY
EOF
}

write_transcript() {
  local repo_dir="$1"
  local text="$2"

  jq -nc --arg text "$text" \
    '{role:"assistant", message:{content:[{type:"text", text:$text}]}}' \
    > "${repo_dir}/transcript.jsonl"
}

run_hook() {
  local repo_dir="$1"

  printf '{"transcript_path":"%s"}\n' "${repo_dir}/transcript.jsonl" \
    | (cd "${repo_dir}" && bash "${HOOK_PATH}")
}

run_hook_via_symlink() {
  local repo_dir="$1"
  local install_dir
  install_dir="$(mktemp -d)"
  mkdir -p "${install_dir}/hooks"
  ln -s "${HOOK_PATH}" "${install_dir}/hooks/stop-hook.sh"

  local output
  output="$(printf '{"transcript_path":"%s"}\n' "${repo_dir}/transcript.jsonl" \
    | (cd "${repo_dir}" && bash "${install_dir}/hooks/stop-hook.sh"))"

  rm -rf "${install_dir}"
  printf '%s' "$output"
}

with_repo() {
  local test_name="$1"
  local repo_dir
  repo_dir="$(mktemp -d)"
  mkdir -p "${repo_dir}/.claude"

  if ! "${test_name}" "${repo_dir}"; then
    rm -rf "${repo_dir}"
    return 1
  fi

  rm -rf "${repo_dir}"
}

test_regular_output_continues() {
  local repo_dir="$1"
  write_state "${repo_dir}" "true" "1" "null"
  write_transcript "${repo_dir}" "regular output"

  local output
  output="$(run_hook "${repo_dir}")"

  assert_contains "$output" '"decision": "block"' "regular output should continue the loop"
  assert_equals "2" "$(state_field "${repo_dir}" "iteration")" "regular output should increment iteration"
  assert_equals "true" "$(state_field "${repo_dir}" "active")" "regular output should keep loop active"
}

test_embedded_complete_marker_does_not_finish() {
  local repo_dir="$1"
  write_state "${repo_dir}" "true" "1" "null"
  write_transcript "${repo_dir}" "I will not emit RALPH_COMPLETE until coverage is good."

  local output
  output="$(run_hook "${repo_dir}")"

  assert_contains "$output" '"decision": "block"' "embedded completion text should not finish the loop"
  assert_equals "2" "$(state_field "${repo_dir}" "iteration")" "embedded completion text should still increment iteration"
}

test_exact_complete_marker_finishes() {
  local repo_dir="$1"
  write_state "${repo_dir}" "true" "1" "null"
  write_transcript "${repo_dir}" "RALPH_COMPLETE"

  local output
  output="$(run_hook "${repo_dir}")"

  assert_contains "$output" "Loop complete." "exact completion marker should finish the loop"
  if [[ -f "${repo_dir}/.claude/ralph-loop.test.local.md" ]]; then
    fail "exact completion marker should delete the state file"
  fi
}

test_embedded_pause_marker_does_not_pause() {
  local repo_dir="$1"
  write_state "${repo_dir}" "true" "1" "null"
  write_transcript "${repo_dir}" "We should document RALPH_PAUSE better."

  local output
  output="$(run_hook "${repo_dir}")"

  assert_contains "$output" '"decision": "block"' "embedded pause text should not pause the loop"
  assert_equals "true" "$(state_field "${repo_dir}" "active")" "embedded pause text should keep loop active"
  assert_equals "2" "$(state_field "${repo_dir}" "iteration")" "embedded pause text should increment iteration"
}

test_exact_pause_marker_pauses() {
  local repo_dir="$1"
  write_state "${repo_dir}" "true" "1" "null"
  write_transcript "${repo_dir}" "RALPH_PAUSE"

  local output
  output="$(run_hook "${repo_dir}")"

  assert_contains "$output" "Paused" "exact pause marker should pause the loop"
  assert_equals "paused" "$(state_field "${repo_dir}" "active")" "exact pause marker should mark the loop paused"
  assert_equals "1" "$(state_field "${repo_dir}" "iteration")" "paused loop should not increment iteration"
}

test_paused_loops_stay_paused() {
  local repo_dir="$1"
  write_state "${repo_dir}" "paused" "1" "null"
  write_transcript "${repo_dir}" "regular output"

  local output
  output="$(run_hook "${repo_dir}")"

  assert_equals "" "$output" "paused loops should be ignored by the hook"
  assert_equals "paused" "$(state_field "${repo_dir}" "active")" "paused loop should remain paused"
  assert_equals "1" "$(state_field "${repo_dir}" "iteration")" "paused loop should not increment iteration"
}

test_embedded_promise_marker_does_not_finish() {
  local repo_dir="$1"
  write_state "${repo_dir}" "true" "1" "\"DONE\""
  write_transcript "${repo_dir}" "Example only: <promise>DONE</promise> is what I would emit later."

  local output
  output="$(run_hook "${repo_dir}")"

  assert_contains "$output" '"decision": "block"' "embedded promise text should not finish the loop"
  assert_equals "2" "$(state_field "${repo_dir}" "iteration")" "embedded promise text should increment iteration"
}

test_exact_promise_marker_finishes() {
  local repo_dir="$1"
  write_state "${repo_dir}" "true" "1" "\"DONE\""
  write_transcript "${repo_dir}" "<promise>DONE</promise>"

  local output
  output="$(run_hook "${repo_dir}")"

  assert_contains "$output" "Promise fulfilled." "exact promise marker should finish the loop"
  if [[ -f "${repo_dir}/.claude/ralph-loop.test.local.md" ]]; then
    fail "exact promise marker should delete the state file"
  fi
}

test_symlinked_hook_resolves_helper_library() {
  local repo_dir="$1"
  write_state "${repo_dir}" "true" "1" "null"
  write_transcript "${repo_dir}" "regular output"

  local output
  output="$(run_hook_via_symlink "${repo_dir}")"

  assert_contains "$output" '"decision": "block"' "symlinked hook should still continue the loop"
  assert_equals "2" "$(state_field "${repo_dir}" "iteration")" "symlinked hook should increment iteration"
}

main() {
  with_repo test_regular_output_continues
  with_repo test_embedded_complete_marker_does_not_finish
  with_repo test_exact_complete_marker_finishes
  with_repo test_embedded_pause_marker_does_not_pause
  with_repo test_exact_pause_marker_pauses
  with_repo test_paused_loops_stay_paused
  with_repo test_embedded_promise_marker_does_not_finish
  with_repo test_exact_promise_marker_finishes
  with_repo test_symlinked_hook_resolves_helper_library

  echo "stop-hook tests passed"
}

main "$@"
