#!/usr/bin/env bash
# Both halves of AGENTS.md rule 9: every page exists in both languages, and the
# German half is not older than the English one it was made from.
#
# A page that exists in one language is a 404 for every reader who switches on
# it, and it makes the two sidebars stop being the same tree. That half is a
# plain existence check, in both directions.
#
# The other half is staleness. Machine translation makes the first pass cheap;
# it does nothing for month two. A German page whose source changed is wrong,
# and invisibly so: the same failure mode as campus drift, in another
# dimension. Recording the source blob hash makes the mismatch mechanical to
# detect.
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

# The other direction. A German page with no English source is caught above;
# this catches an English page that was never mirrored, which is the more
# common way the pair breaks.
while IFS= read -r en_page; do
  de_page="content/de/${en_page#content/en/}"

  if [ ! -f "$de_page" ]; then
    echo "✗ ${en_page}"
    echo "  No German counterpart at ${de_page}."
    echo "  fix: npm run new-page creates the pair, or write a German stub that says"
    echo "       what it is. A stub beats a missing file: the reader still lands"
    echo "       somewhere and the language switcher still works."
    echo "  its translatedFrom would be: $(git hash-object "$en_page")"
    echo
    fail=1
  fi
done < <(find content/en -name '*.md' 2>/dev/null | sort)

if [ "$fail" -eq 0 ]; then
  echo "✓ ${checked} page(s) exist in both languages and match their English source"
fi

exit "$fail"
