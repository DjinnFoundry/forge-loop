#!/usr/bin/env bash
set -euo pipefail

forge_frontmatter() {
  sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$1"
}

forge_frontmatter_value() {
  local file="$1"
  local key="$2"

  forge_frontmatter "$file" \
    | awk -F: -v key="$key" '$1 == key { sub(/^[^:]+:[[:space:]]*/, "", $0); print; exit }'
}

forge_strip_quotes() {
  local value="${1:-}"
  value="${value#\"}"
  value="${value%\"}"
  printf '%s' "$value"
}
