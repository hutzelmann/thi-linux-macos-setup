#!/usr/bin/env bash
# Enforce R23: a documented value lives in facts/ and nowhere else.
#
# Pages reference values as ${facts.domain.key}, substituted at build time. A
# literal hostname or queue name in page source means someone typed it by hand,
# and the next rename will miss it. That already happened here once: the print
# server moved from marb-mfp to rz-print-marb.
#
# Uses `git grep` rather than `grep -r --include`: it respects .gitignore (so
# build output is never scanned) and behaves identically everywhere, including
# on systems where `grep` is actually ugrep or BSD grep.
set -euo pipefail

cd "$(dirname "$0")/../.."

fail=0

# Values shorter than this can occur coincidentally in prose. The check targets
# identifiers, not words.
MIN_LENGTH=8

flatten_facts() {
  # facts/*.yaml are one level deep by contract (AGENTS.md), so a YAML parser is
  # not needed and the check stays dependency-free.
  local file domain
  for file in facts/*.yaml; do
    domain=$(basename "$file" .yaml)
    sed -n 's/^\([a-z0-9_]*\):[[:space:]]*\(.*\)$/\1=\2/p' "$file" |
      sed "s/^/${domain}./" |
      sed 's/="\(.*\)"$/=\1/'
  done
}

while IFS='=' read -r key value; do
  [ -n "$value" ] || continue
  [ "${#value}" -ge "$MIN_LENGTH" ] || continue

  if hits=$(git grep -nF --untracked -- "$value" 'content/**/*.md' 2>/dev/null); then
    echo "✗ Literal value from facts/ found in page source"
    echo "  fact:  \${facts.${key}}"
    echo "  value: ${value}"
    echo "$hits" | sed 's/^/  /'
    echo "  fix:   replace the literal with \${facts.${key}}"
    echo
    fail=1
  fi
done < <(flatten_facts)

if [ "$fail" -eq 0 ]; then
  echo "✓ No hardcoded fact values in content/"
fi

exit "$fail"
