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
# What counts as an answer, and the exit codes the workflow reads, are in
# lib/url-check.sh, next to the same decision for the values in facts/. What is
# here is the list, how a line reads, and what a person does about it. Several
# of these pages link to forums that answer a browser and decline curl, which
# is why a refusal is an answer there and not a finding.
set -euo pipefail

# $0 is the shell when this file is sourced rather than run, and the guard at
# the foot exists so that it can be. BASH_SOURCE is this file either way.
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

# shellcheck source=lib/url-check.sh
. scripts/ci/lib/url-check.sh

work=

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
#
# A miss is tolerated rather than fatal. The addresses come out of these files,
# so there should always be one, but `set -e` and a pipeline that reports grep's
# status would end the run at the first address that somehow had none, halfway
# through the report and with no line saying why.
where() {
  grep -rlF "$1" content/en content/de --include='*.md' |
    sed 's|^|         |' || true
}

# An address in prose is written into two pages, so the edit is a page and its
# counterpart rather than a value. The pages naming it were printed under it as
# each one was reached.
report_differs() {
  echo
  echo "An address that stopped answering is an observation, not a fault."
  echo "Find the current one, then edit the page and its counterpart."
}

report_ok() {
  echo "Every address that answered a script answered with a page."
}

main() {
  local url code reason checked=0 refused=0 differs=0 unreached=0

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT

  while read -r url; do
    [ -n "$url" ] || continue
    checked=$((checked + 1))

    probe "$url"

    case "$(classify "$code")" in
      ok)
        printf '  ok    %s\n' "$url"
        ;;
      refused)
        printf '  skip  %s  (%s, refuses automated clients)\n' "$url" "$code"
        refused=$((refused + 1))
        ;;
      unreached)
        # The pages naming it are not listed: there is nothing yet to act on.
        printf '  ?     %s  (not reached)\n' "$url"
        if [ -n "$reason" ]; then
          printf '        %s\n' "$reason"
        fi
        unreached=$((unreached + 1))
        ;;
      differs)
        printf '  ✗     %s  (%s)\n' "$url" "$code"
        where "$url"
        differs=$((differs + 1))
        ;;
    esac
  done < <(collect)

  echo
  printf '%s address(es) checked, %s refused automated clients, %s not reached.\n' \
    "$checked" "$refused" "$unreached"

  verdict "$differs" "$unreached"
}

# Entry point. Guarded so the functions above can be sourced and called.
case "${0##*/}" in
  check-content-urls.sh) main "$@" ;;
esac
