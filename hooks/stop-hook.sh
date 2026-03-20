#!/bin/bash

# Forge Loop Stop Hook
# Prevents session exit when a forge/ralph loop is active
# Feeds the prompt back as input to continue the loop
# Compatible with Ralph Wiggum loops (same state file format)

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Get transcript path from hook input (unique per session)
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

# Cleanup stale state files (older than 24 hours)
cleanup_stale_files() {
  find .claude -maxdepth 1 -name 'ralph-loop.*.local.md' -mmin +1440 -delete 2>/dev/null || true
}

# Find state file for current session
find_session_state_file() {
  local transcript="$1"

  for state_file in .claude/ralph-loop.*.local.md; do
    [[ -f "$state_file" ]] || continue

    local stored_transcript
    stored_transcript=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$state_file" | grep '^session_transcript:' | sed 's/session_transcript: *//' | sed 's/^"\(.*\)"$/\1/')

    # If unclaimed (null or empty), claim it for this session
    if [[ "$stored_transcript" == "null" ]] || [[ -z "$stored_transcript" ]]; then
      local temp_file="${state_file}.tmp.$$"
      sed "s|^session_transcript:.*|session_transcript: \"$transcript\"|" "$state_file" > "$temp_file"
      mv "$temp_file" "$state_file"
      echo "$state_file"
      return 0
    fi

    # If this file belongs to our session, use it
    if [[ "$stored_transcript" == "$transcript" ]]; then
      echo "$state_file"
      return 0
    fi
  done

  echo ""
  return 0
}

# Run cleanup on every invocation
cleanup_stale_files

# Ensure .claude directory exists
[[ -d ".claude" ]] || exit 0

# Find state file for this session
STATE_FILE=$(find_session_state_file "$TRANSCRIPT_PATH")

if [[ -z "$STATE_FILE" ]] || [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Parse frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')
SESSION_ID=$(basename "$STATE_FILE" | sed 's/ralph-loop\.\(.*\)\.local\.md/\1/')

# Validate numeric fields
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "Warning: Forge loop [$SESSION_ID]: State file corrupted (iteration: '$ITERATION')" >&2
  rm "$STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "Warning: Forge loop [$SESSION_ID]: State file corrupted (max_iterations: '$MAX_ITERATIONS')" >&2
  rm "$STATE_FILE"
  exit 0
fi

# Check max iterations
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "Forge loop [$SESSION_ID]: Max iterations ($MAX_ITERATIONS) reached."
  rm "$STATE_FILE"
  exit 0
fi

# Read transcript
if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "Warning: Forge loop [$SESSION_ID]: Transcript not found" >&2
  rm "$STATE_FILE"
  exit 0
fi

if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  echo "Warning: Forge loop [$SESSION_ID]: No assistant messages in transcript" >&2
  rm "$STATE_FILE"
  exit 0
fi

LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
if [[ -z "$LAST_LINE" ]]; then
  echo "Warning: Forge loop [$SESSION_ID]: Failed to extract last message" >&2
  rm "$STATE_FILE"
  exit 0
fi

LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
  .message.content |
  map(select(.type == "text")) |
  map(.text) |
  join("\n")
' 2>&1)

if [[ $? -ne 0 ]] || [[ -z "$LAST_OUTPUT" ]]; then
  echo "Warning: Forge loop [$SESSION_ID]: Failed to parse assistant message" >&2
  rm "$STATE_FILE"
  exit 0
fi

# Check for completion
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")
  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
    echo "Forge loop [$SESSION_ID]: Promise fulfilled."
    rm "$STATE_FILE"
    exit 0
  fi
else
  if echo "$LAST_OUTPUT" | grep -q "RALPH_COMPLETE"; then
    echo "Forge loop [$SESSION_ID]: All targets met. Loop complete."
    rm "$STATE_FILE"
    exit 0
  fi
fi

# Check for pause
if echo "$LAST_OUTPUT" | grep -q "RALPH_PAUSE"; then
  echo "Forge loop [$SESSION_ID]: Paused — waiting for user input."
  TEMP_FILE="${STATE_FILE}.tmp.$$"
  sed -e "s/^active: .*/active: paused/" -e 's/^session_transcript: .*/session_transcript: null/' "$STATE_FILE" > "$TEMP_FILE"
  mv "$TEMP_FILE" "$STATE_FILE"
  exit 0
fi

# Continue loop — re-inject prompt
NEXT_ITERATION=$((ITERATION + 1))

PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$STATE_FILE")

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "Warning: Forge loop [$SESSION_ID]: No prompt found in state file" >&2
  rm "$STATE_FILE"
  exit 0
fi

# Update iteration counter
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"

# Build system message
PAUSE_HINT="To pause for user input: output RALPH_PAUSE."
STUCK_HINT="If stuck, try a different approach — do not repeat the same failing strategy."
DIRECT_HINT="Output markers DIRECTLY in your response — do not quote them or say you 'will' output them."

if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  SYSTEM_MSG="Forge [$SESSION_ID] iteration $NEXT_ITERATION | To stop: output <promise>$COMPLETION_PROMISE</promise> (ONLY when TRUE). $DIRECT_HINT $PAUSE_HINT $STUCK_HINT"
else
  SYSTEM_MSG="Forge [$SESSION_ID] iteration $NEXT_ITERATION | To stop: output RALPH_COMPLETE when all targets are met. $DIRECT_HINT $PAUSE_HINT $STUCK_HINT"
fi

jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
