#!/usr/bin/env bash
# Docs-integrity tests for the Forge protocol source of truth.
#
# Forge is largely a protocol *document* (skills/forge/SKILL.md), so its
# integrity is part of the product surface. These checks guard the canonical
# state schema, internal cross-references, and table consistency against the
# class of drift a manual review would otherwise have to catch every time.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="${ROOT_DIR}/skills/forge/SKILL.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$SKILL" ]] || fail "source of truth not found: $SKILL"

# --- 1. The canonical forge-state YAML example must be valid YAML -------------
# Extract the first ```yaml fenced block, then its frontmatter portion (between
# the leading '---' and the next '---'). Parse it with whatever YAML-capable
# interpreter is on the box; if none is available, warn and skip rather than
# fail spuriously (the suite stays dependency-light, like the others).
test_state_yaml_parses() {
  local block frontmatter
  block="$(awk '/^```yaml$/{f=1;next} /^```$/{if(f)exit} f' "$SKILL")"
  [[ -n "$block" ]] || fail "no \`\`\`yaml example block found in SKILL.md"

  frontmatter="$(printf '%s\n' "$block" | awk '
    NR==1 && $0=="---"{next}
    /^---$/{exit}
    {print}
  ')"
  [[ -n "$frontmatter" ]] || fail "could not extract YAML frontmatter from the example block"

  local tmp
  tmp="$(mktemp)"
  printf '%s\n' "$frontmatter" > "$tmp"

  if command -v ruby >/dev/null 2>&1; then
    ruby -ryaml -e 'YAML.safe_load(File.read(ARGV[0]), permitted_classes: [], aliases: false)' "$tmp" \
      || { rm -f "$tmp"; fail "canonical forge-state YAML example does not parse (ruby)"; }
    echo "  ok: canonical forge-state YAML parses (ruby)"
  elif command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
    python3 -c 'import sys,yaml; yaml.safe_load(open(sys.argv[1]))' "$tmp" \
      || { rm -f "$tmp"; fail "canonical forge-state YAML example does not parse (python3)"; }
    echo "  ok: canonical forge-state YAML parses (python3)"
  else
    echo "  WARN: no YAML parser (ruby/python3+pyyaml) available — skipping YAML validity check"
  fi
  rm -f "$tmp"
}

# --- 2. Every "§ Section" cross-reference must resolve to a real header --------
# Build the set of referenceable anchors from ## and ### headers, normalizing
# phase headers ("### A. ORIENT — Read State") to their stable prefix
# ("A. ORIENT"). A reference is valid when its text starts with a known anchor
# (this tolerates trailing words like '§ G. RECORD step "Persist…"').
test_cross_references_resolve() {
  local anchors
  anchors="$(grep -E '^#{2,3} ' "$SKILL" | sed -E 's/^#{2,3} //; s/ — .*$//')"

  local ref matched
  while IFS= read -r ref; do
    ref="${ref#§ }"
    [[ -n "$ref" ]] || continue
    matched=0
    while IFS= read -r anchor; do
      [[ -n "$anchor" ]] || continue
      if [[ "$ref" == "$anchor"* ]]; then matched=1; break; fi
    done <<< "$anchors"
    [[ $matched -eq 1 ]] || fail "dangling cross-reference: § ${ref}"
  done < <(tr '\n' ' ' < "$SKILL" | tr -s ' ' | grep -oE '§ [A-Za-z0-9][A-Za-z0-9 ./&-]*')
  echo "  ok: all § cross-references resolve to a section header"
}

# --- 3. The two capability tables must list the same capabilities -------------
test_capability_tables_consistent() {
  local abstract driver
  # Capability name is the first column only: lines like "| `name` | ... | ... |".
  abstract="$(awk '/^### Abstract capabilities/{f=1;next} /^\*\*Every capability/{f=0} f' "$SKILL" \
    | sed -nE 's/^\| `([a-z_]+)`.*/\1/p' | sort -u)"
  driver="$(awk '/^### Driver capability map/{f=1;next} /first-class/{f=0} f' "$SKILL" \
    | sed -nE 's/^\| `([a-z_]+)`.*/\1/p' | sort -u)"

  [[ -n "$abstract" ]] || fail "no capabilities parsed from the abstract table"
  [[ -n "$driver" ]] || fail "no capabilities parsed from the driver map"
  if [[ "$abstract" != "$driver" ]]; then
    fail "capability tables differ:
abstract:
$abstract
driver map:
$driver"
  fi
  echo "  ok: abstract + driver capability tables list the same $(printf '%s\n' "$abstract" | grep -c . ) capabilities"
}

# --- 4. Critical Rules must be numbered 1..N with no gaps or duplicates --------
test_critical_rules_contiguous() {
  local nums expected=1
  nums="$(awk '/^## Critical Rules/{f=1;next} /^## /{if(f)exit} f' "$SKILL" \
    | grep -oE '^[0-9]+\.' | tr -d '.')"
  [[ -n "$nums" ]] || fail "no numbered Critical Rules found"
  while IFS= read -r n; do
    [[ "$n" == "$expected" ]] || fail "Critical Rules numbering broken: expected ${expected}, got ${n}"
    expected=$((expected + 1))
  done <<< "$nums"
  echo "  ok: Critical Rules numbered 1..$((expected - 1)) contiguously"
}

main() {
  test_state_yaml_parses
  test_cross_references_resolve
  test_capability_tables_consistent
  test_critical_rules_contiguous
  echo "docs-integrity tests passed"
}

main "$@"
