#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INIT_PATH="${ROOT_DIR}/drivers/codex/bin/forge-init"
CONTINUE_PATH="${ROOT_DIR}/drivers/codex/bin/forge-continue"
CANCEL_PATH="${ROOT_DIR}/drivers/codex/bin/forge-cancel"
STATUS_PATH="${ROOT_DIR}/drivers/codex/bin/forge-status"
RUN_PATH="${ROOT_DIR}/drivers/codex/bin/forge-run"
INSTALL_PATH="${ROOT_DIR}/install-codex.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "$haystack" != *"$needle"* ]]; then
    fail "${message}: missing '${needle}'"
  fi
}

assert_file() {
  local path="$1"
  local message="$2"

  if [[ ! -f "$path" ]]; then
    fail "${message}: missing file '${path}'"
  fi
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$expected" != "$actual" ]]; then
    fail "${message}: expected '${expected}', got '${actual}'"
  fi
}

test_codex_init_continue_cancel() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  (
    cd "$repo_dir"
    output_init="$("$INIT_PATH" "API controllers" --done-when "reset flow works end-to-end" --coverage 90 --speed -30% --quality strict --max-iterations 5)"
    assert_contains "$output_init" "Initialized Forge Codex driver session" "forge-init should initialize a session"
    session_id="$(printf '%s\n' "$output_init" | awk '/Initialized Forge Codex driver session/ {print $6}' | tr -d '.')"
    assert_file ".codex/forge/forge-state.${session_id}.md" "forge-init should create Forge state"
    assert_file ".codex/forge/loop-state.${session_id}.md" "forge-init should create loop state"
    assert_contains "$(cat ".codex/forge/forge-state.${session_id}.md")" 'done_when: "reset flow works end-to-end"' "forge-init should persist explicit done_when"

    output_continue="$("$CONTINUE_PATH" "$session_id")"
    assert_contains "$output_continue" "iteration 1" "forge-continue should report current iteration before incrementing"
    assert_contains "$output_continue" "DONE WHEN: reset flow works end-to-end" "forge-continue should render explicit done_when into the prompt"
    next_iteration="$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' ".codex/forge/loop-state.${session_id}.md" | awk -F: '$1=="iteration" { sub(/^[^:]+:[[:space:]]*/, "", $0); print; exit }')"
    assert_equals "1" "$next_iteration" "forge-continue should align loop state with the next required recorded iteration"

    output_continue_repeat="$("$CONTINUE_PATH" "$session_id")"
    assert_contains "$output_continue_repeat" "iteration 1" "forge-continue should not silently drift iterations when forge-state has not advanced"

    cat >> ".codex/forge/forge-state.${session_id}.md" <<'EOF'

## Iteration 1 - coverage-push
- Coverage: 80.0 -> 80.8 (+0.8%)
EOF

    output_continue_after_record="$("$CONTINUE_PATH" "$session_id")"
    assert_contains "$output_continue_after_record" "iteration 2" "forge-continue should advance after forge-state records iteration 1"

    output_cancel="$("$CANCEL_PATH" "$session_id")"
    assert_contains "$output_cancel" "Cancelled Forge Codex driver session ${session_id}." "forge-cancel should cancel the session"
    [[ ! -f ".codex/forge/loop-state.${session_id}.md" ]] || fail "forge-cancel should remove loop state"
    assert_file ".codex/forge/forge-state.${session_id}.md" "forge-cancel should preserve Forge state"
  )
  rm -rf "$repo_dir"
}

test_open_text_success_contract_round_trips() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  (
    cd "$repo_dir"
    scope='Ship "forgot password" / email fallback'
    done_when='users can finish "forgot password" & email fallback end-to-end'

    output_init="$("$INIT_PATH" "$scope" --done-when "$done_when")"
    session_id="$(printf '%s\n' "$output_init" | awk '/Initialized Forge Codex driver session/ {print $6}' | tr -d '.')"
    forge_state_path=".codex/forge/forge-state.${session_id}.md"

    assert_contains "$(cat "$forge_state_path")" 'scope: "Ship \"forgot password\" / email fallback"' "forge-init should YAML-escape open text scope"
    assert_contains "$(cat "$forge_state_path")" 'done_when: "users can finish \"forgot password\" & email fallback end-to-end"' "forge-init should YAML-escape explicit done_when"

    output_continue="$("$CONTINUE_PATH" "$session_id")"
    assert_contains "$output_continue" "SCOPE: ${scope}" "forge-continue should render unescaped scope text"
    assert_contains "$output_continue" "DONE WHEN: ${done_when}" "forge-continue should render unescaped done_when text"

    output_status="$("$STATUS_PATH" "$session_id")"
    assert_contains "$output_status" "Scope: ${scope}" "forge-status should render unescaped scope text"
    assert_contains "$output_status" "Done when: ${done_when}" "forge-status should render unescaped done_when text"
  )
  rm -rf "$repo_dir"
}

test_codex_install() {
  local repo_dir tmp_home
  repo_dir="$(mktemp -d)"
  tmp_home="$(mktemp -d)"
  (
    cd "$ROOT_DIR"
    output_install="$(HOME="$tmp_home" "$INSTALL_PATH")"
    assert_contains "$output_install" "Installing forge-loop Codex driver" "install-codex should announce itself"
    assert_file "$tmp_home/.codex/skills/forge/SKILL.md" "install-codex should link Forge skill"
    assert_file "$tmp_home/.codex/bin/forge-init" "install-codex should link forge-init"
    assert_file "$tmp_home/.codex/bin/forge-continue" "install-codex should link forge-continue"
    assert_file "$tmp_home/.codex/bin/forge-cancel" "install-codex should link forge-cancel"
    assert_file "$tmp_home/.codex/bin/forge-status" "install-codex should link forge-status"
    assert_file "$tmp_home/.codex/bin/forge-run" "install-codex should link forge-run"
  )
  rm -rf "$repo_dir" "$tmp_home"
}

test_multiple_active_sessions_require_explicit_id() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  (
    cd "$repo_dir"
    output_init_one="$("$INIT_PATH" "Scope one")"
    session_one="$(printf '%s\n' "$output_init_one" | awk '/Initialized Forge Codex driver session/ {print $6}' | tr -d '.')"
    output_init_two="$("$INIT_PATH" "Scope two")"
    session_two="$(printf '%s\n' "$output_init_two" | awk '/Initialized Forge Codex driver session/ {print $6}' | tr -d '.')"

    if "$CONTINUE_PATH" >/tmp/forge-multi.out 2>/tmp/forge-multi.err; then
      fail "forge-continue should fail when multiple active sessions exist without an explicit id"
    fi

    assert_contains "$(cat /tmp/forge-multi.err)" "Multiple active Codex Forge sessions found" "forge-continue should explain the ambiguity"

    output_continue="$("$CONTINUE_PATH" "$session_one")"
    assert_contains "$output_continue" "$session_one" "forge-continue should accept an explicit session id"

    output_cancel="$("$CANCEL_PATH" "$session_two")"
    assert_contains "$output_cancel" "$session_two" "forge-cancel should accept an explicit session id"
    rm -f /tmp/forge-multi.out /tmp/forge-multi.err
  )
  rm -rf "$repo_dir"
}

test_status_and_error_paths() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  (
    cd "$repo_dir"
    output_init="$("$INIT_PATH" "Status scope" --max-iterations 2)"
    session_id="$(printf '%s\n' "$output_init" | awk '/Initialized Forge Codex driver session/ {print $6}' | tr -d '.')"

    output_status="$("$STATUS_PATH" "$session_id")"
    assert_contains "$output_status" "Session: ${session_id}" "forge-status should report the session"
    assert_contains "$output_status" "Next iteration: 1" "forge-status should report the next required iteration"
    assert_contains "$output_status" "Success mode: task-derived" "forge-status should report task-derived success mode when no override is provided"

    sed -i.bak 's/^max_iterations: .*/max_iterations: nope/' ".codex/forge/loop-state.${session_id}.md"
    rm -f ".codex/forge/loop-state.${session_id}.md.bak"
    if "$CONTINUE_PATH" "$session_id" >/tmp/forge-invalid.out 2>/tmp/forge-invalid.err; then
      fail "forge-continue should fail on invalid max_iterations metadata"
    fi
    assert_contains "$(cat /tmp/forge-invalid.err)" "invalid iteration metadata" "forge-continue should report invalid iteration metadata"

    sed -i.bak 's/^max_iterations: .*/max_iterations: 1/' ".codex/forge/loop-state.${session_id}.md"
    rm -f ".codex/forge/loop-state.${session_id}.md.bak"
    cat >> ".codex/forge/forge-state.${session_id}.md" <<'EOF'

## Iteration 1 - done
- Coverage: 80.0 -> 81.0 (+1.0%)
EOF
    if "$CONTINUE_PATH" "$session_id" >/tmp/forge-max.out 2>/tmp/forge-max.err; then
      fail "forge-continue should fail after max_iterations is exhausted"
    fi
    assert_contains "$(cat /tmp/forge-max.err)" "already past max_iterations" "forge-continue should report max-iteration exhaustion"
    rm -f /tmp/forge-invalid.out /tmp/forge-invalid.err /tmp/forge-max.out /tmp/forge-max.err
  )
  rm -rf "$repo_dir"
}

# Regression: the installer links scripts into ~/.codex/bin, so they must resolve
# their own symlink to find lib.sh / prompt.md. Invoking through a symlink (as a real
# install does) must work, not just running them by their repo path.
test_scripts_work_through_symlink() {
  local repo_dir bin_dir
  repo_dir="$(mktemp -d)"
  bin_dir="$(mktemp -d)"
  ln -s "$INIT_PATH" "${bin_dir}/forge-init"
  ln -s "$STATUS_PATH" "${bin_dir}/forge-status"
  (
    cd "$repo_dir"
    output_init="$("${bin_dir}/forge-init" "symlinked scope" --coverage 90)"
    assert_contains "$output_init" "Initialized Forge Codex driver session" "forge-init must work when invoked through a symlink (real install path)"
    session_id="$(printf '%s\n' "$output_init" | awk '/Initialized Forge Codex driver session/ {print $6}' | tr -d '.')"
    assert_file ".codex/forge/forge-state.${session_id}.md" "symlinked forge-init should create Forge state"
    output_status="$("${bin_dir}/forge-status" "$session_id")"
    assert_contains "$output_status" "Session: ${session_id}" "forge-status must work when invoked through a symlink"
  )
  rm -rf "$repo_dir" "$bin_dir"
}

# forge-run drives the loop autonomously via `codex exec`. We mock the codex binary
# (FORGE_CODEX_BIN) so the loop logic is tested without a real model or token spend:
# the mock records one iteration per call and emits FORGE_COMPLETE on the second.
test_forge_run_autoiterates_until_complete() {
  local repo_dir bin_dir
  repo_dir="$(mktemp -d)"
  bin_dir="$(mktemp -d)"
  cat > "${bin_dir}/codex" <<'MOCK'
#!/usr/bin/env bash
# Mock `codex exec`: simulate one Forge iteration by recording it in forge-state,
# and signal completion on the second iteration.
shift || true   # drop the `exec` subcommand; ignore flags + prompt
state="$(ls .codex/forge/forge-state.*.md 2>/dev/null | head -1)"
[[ -n "$state" ]] || { echo "mock: no forge-state found" >&2; exit 1; }
n=$(( $(grep -c '^## Iteration ' "$state") + 1 ))
printf '\n## Iteration %d - mock\n- Coverage: +1.0%%\n' "$n" >> "$state"
echo "mock codex ran iteration ${n}"
if (( n >= 2 )); then echo "FORGE_COMPLETE"; fi
MOCK
  chmod +x "${bin_dir}/codex"
  (
    cd "$repo_dir"
    output="$(FORGE_CODEX_BIN="${bin_dir}/codex" FORGE_CODEX_ARGS=" " "$RUN_PATH" "autonomous scope" --max-iterations 5)"
    assert_contains "$output" "FORGE_COMPLETE — session" "forge-run should stop on FORGE_COMPLETE"
    state_file="$(ls .codex/forge/forge-state.*.md | head -1)"
    iteration_count="$(grep -c '^## Iteration ' "$state_file" || true)"
    assert_equals "2" "$iteration_count" "forge-run should iterate until the completion marker (2 mock iterations)"
    loop_file="$(ls .codex/forge/loop-state.*.md | head -1)"
    assert_contains "$(grep '^active:' "$loop_file")" "false" "forge-run should deactivate loop state when the run ends"
  )
  rm -rf "$repo_dir" "$bin_dir"
}

# forge-run must stop instead of looping forever when an iteration records no progress.
test_forge_run_stops_on_stall() {
  local repo_dir bin_dir
  repo_dir="$(mktemp -d)"
  bin_dir="$(mktemp -d)"
  cat > "${bin_dir}/codex" <<'MOCK'
#!/usr/bin/env bash
# Mock that never records progress and never completes.
shift || true
echo "mock codex did nothing"
MOCK
  chmod +x "${bin_dir}/codex"
  (
    cd "$repo_dir"
    output="$(FORGE_CODEX_BIN="${bin_dir}/codex" FORGE_CODEX_ARGS=" " "$RUN_PATH" "stall scope" --max-iterations 9 2>&1)"
    assert_contains "$output" "no progress" "forge-run should detect a stall"
    assert_contains "$output" "without a completion marker" "forge-run should report it stopped without completing"
    state_file="$(ls .codex/forge/forge-state.*.md | head -1)"
    iteration_count="$(grep -c '^## Iteration ' "$state_file" || true)"
    assert_equals "0" "$iteration_count" "forge-run should not fabricate iterations on a stall"
  )
  rm -rf "$repo_dir" "$bin_dir"
}

main() {
  test_codex_init_continue_cancel
  test_open_text_success_contract_round_trips
  test_codex_install
  test_multiple_active_sessions_require_explicit_id
  test_status_and_error_paths
  test_scripts_work_through_symlink
  test_forge_run_autoiterates_until_complete
  test_forge_run_stops_on_stall
  echo "codex-driver tests passed"
}

main "$@"
