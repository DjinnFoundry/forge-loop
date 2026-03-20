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

forge_nested_frontmatter_value() {
  local file="$1"
  local section="$2"
  local key="$3"

  forge_frontmatter "$file" | awk -v section="$section" -v key="$key" '
    /^[^[:space:]].*:[[:space:]]*$/ {
      in_section = ($1 == section ":")
      next
    }
    in_section && $0 ~ ("^  " key ":") {
      sub("^  " key ":[[:space:]]*", "", $0)
      print
      exit
    }
  '
}

forge_yaml_quote() {
  local value="${1:-}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '"%s"' "$value"
}

forge_sed_escape() {
  local value="${1:-}"
  value="${value//\\/\\\\}"
  value="${value//&/\\&}"
  value="${value//\//\\/}"
  printf '%s' "$value"
}

forge_strip_quotes() {
  local value="${1:-}"
  value="${value#\"}"
  value="${value%\"}"
  value="${value//\\n/$'\n'}"
  value="${value//\\\"/\"}"
  value="${value//\\\\/\\}"
  printf '%s' "$value"
}
