#!/usr/bin/env bash
# Ask whether every address the pages link to still answers.
#
# check-fact-urls.sh covers the addresses written down in facts/. It does not
# cover the ones written into prose, and those are the majority: vendor
# downloads, distribution wikis, forum threads, Microsoft documentation. A
# vendor reorganises a support site and a page quietly starts sending readers
# to a 404 without anybody editing anything, which is exactly the failure the
# weekly run exists to catch.
#
# One request per distinct address, no crawling, no guessing at addresses
# nobody linked. Anything holding a ${facts...} reference is skipped: it is
# checked by the other script, at the value it actually resolves to.
#
# An address that refuses automated clients is reported and does not fail the
# run. Several of the pages link to forums that answer a browser and reject
# curl, and a check that cries every Monday is a check people learn to ignore.
set -euo pipefail

cd "$(dirname "$0")/../.."

# Every http(s) address in the pages, with the file it appears in.
#
# Trailing punctuation is stripped because a URL at the end of a sentence
# collects it: the closing bracket of a markdown link, a comma, a full stop.
collect() {
  grep -rohE 'https?://[^][)"'"'"'<>[:space:]]+' content/en content/de --include='*.md' |
    sed -E 's/[.,;:]+$//' |
    grep -v '\${' |
    sort -u
}

# Which pages link to an address, for a report somebody has to act on.
where() {
  grep -rlF "$1" content/en content/de --include='*.md' |
    sed 's|^|         |'
}

main() {
  local fail=0 checked=0 refused=0 url code

  while read -r url; do
    [ -n "$url" ] || continue
    checked=$((checked + 1))

    code=$(curl -sSL -o /dev/null -w '%{http_code}' --max-time 20 \
      -A 'thi-setup-notes link check' "$url" 2>/dev/null || echo 000)

    case "$code" in
      2* | 3*)
        printf '  ok    %s\n' "$url"
        ;;
      401 | 403 | 405 | 429)
        # Answered, and declined to answer a script. That is a fact about the
        # host's bot policy, not about whether the link works for a reader.
        printf '  skip  %s  (%s, refuses automated clients)\n' "$url" "$code"
        refused=$((refused + 1))
        ;;
      000)
        printf '  ✗     %s  (no answer)\n' "$url"
        where "$url"
        fail=1
        ;;
      *)
        printf '  ✗     %s  (%s)\n' "$url" "$code"
        where "$url"
        fail=1
        ;;
    esac
  done < <(collect)

  echo
  printf '%s address(es) checked, %s refused automated clients.\n' "$checked" "$refused"

  if [ "$fail" -eq 0 ]; then
    echo "Every address that answered a script answered with a page."
  else
    echo
    echo "An address that stopped answering is an observation, not a fault."
    echo "Find the current one, then edit the page and its counterpart."
  fi

  return "$fail"
}

# Entry point. Guarded so the functions above can be sourced and called.
case "${0##*/}" in
  check-content-urls.sh) main "$@" ;;
esac
