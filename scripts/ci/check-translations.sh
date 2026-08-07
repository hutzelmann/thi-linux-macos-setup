#!/usr/bin/env bash
# Enforce R38: detect German pages whose English source has moved on.
#
# Machine translation makes the first pass cheap; it does nothing for month two.
# A German page whose source changed is wrong, and invisibly so: the same
# failure mode as campus drift, in another dimension. Recording the source blob
# hash makes the mismatch mechanical to detect.
set -euo pipefail

cd "$(dirname "$0")/../.."

fail=0
checked=0

while IFS= read -r de_page; do
  en_page="content/en/${de_page#content/de/}"

  if [ ! -f "$en_page" ]; then
    echo "✗ ${de_page}"
    echo "  No English source at ${en_page}."
    echo "  fix: English is the source of truth. Add it, or remove the German page."
    echo
    fail=1
    continue
  fi

  recorded=$(sed -n 's/^translatedFrom:[[:space:]]*//p' "$de_page" | head -1 | tr -d '"')
  if [ -z "$recorded" ]; then
    echo "✗ ${de_page}"
    echo "  Missing translatedFrom in frontmatter."
    echo "  fix: translatedFrom: $(git hash-object "$en_page")"
    echo
    fail=1
    continue
  fi

  current=$(git hash-object "$en_page")
  checked=$((checked + 1))

  if [ "$recorded" != "$current" ]; then
    echo "✗ ${de_page}"
    echo "  ${en_page} changed since this translation was made."
    echo "  recorded: ${recorded}"
    echo "  current:  ${current}"
    echo "  fix: retranslate, then set translatedFrom: ${current}"
    echo "  see:  git diff ${recorded} ${current} -- ${en_page}"
    echo
    fail=1
  fi
done < <(find content/de -name '*.md' 2>/dev/null | sort)

if [ "$fail" -eq 0 ]; then
  echo "✓ ${checked} translation(s) match their English source"
fi

exit "$fail"
