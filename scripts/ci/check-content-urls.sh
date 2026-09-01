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
#
# Exit codes, because the caller files a public issue from them:
#
#   0  every address that answered a script answered with a page
#   1  an address answered, and what it answered differs from the page
#   2  no status was seen, so there is nothing to say
#
# The difference between 1 and 2 is the same one check-vpn-chain.sh draws. A
# request that never reached a server has not seen a status, and filing that as
# a link that stopped answering is a claim about something nobody looked at.
set -euo pipefail

cd "$(dirname "$0")/../.."

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
where() {
  grep -rlF "$1" content/en content/de --include='*.md' |
    sed 's|^|         |'
}

# One request, keeping both halves of what curl says: the status, on stdout,
# and the reason there is no status, on stderr.
#
# The status is read from stdout and never reconstructed from the exit code.
# curl writes its `--write-out` output before exiting non-zero, so the
# `|| echo 000` this used to carry appended a second 000 to a status that
# already said 000. The result was `000000`, which matched no case below.
probe() {
  code=$(curl -sSL -o /dev/null -w '%{http_code}' --max-time 20 \
    -A 'thi-setup-notes link check' "$1" 2>"$work/reason") || true
  [ -n "$code" ] || code=000
  reason=$(tr -d '\r' <"$work/reason" | tail -n 1)
}

main() {
  local url code reason checked=0 refused=0 differs=0 unreached=0

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT

  while read -r url; do
    [ -n "$url" ] || continue
    checked=$((checked + 1))

    probe "$url"

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
        # No status at all, so this run saw nothing about this address. The
        # pages naming it are not listed: there is nothing yet to act on.
        printf '  ?     %s  (not reached)\n' "$url"
        if [ -n "$reason" ]; then
          printf '        %s\n' "$reason"
        fi
        unreached=$((unreached + 1))
        ;;
      *)
        printf '  ✗     %s  (%s)\n' "$url" "$code"
        where "$url"
        differs=$((differs + 1))
        ;;
    esac
  done < <(collect)

  echo
  printf '%s address(es) checked, %s refused automated clients, %s not reached.\n' \
    "$checked" "$refused" "$unreached"

  if [ "$differs" -gt 0 ]; then
    echo
    echo "An address that stopped answering is an observation, not a fault."
    echo "Find the current one, then edit the page and its counterpart."
    return 1
  fi

  if [ "$unreached" -gt 0 ]; then
    echo
    echo "No status was seen for $unreached of them, so nothing was observed about"
    echo "those. That is an account of the network this run had, not of the"
    echo "pages, and there is nothing to report from it."
    return 2
  fi

  echo "Every address that answered a script answered with a page."
  return 0
}

# Entry point. Guarded so the functions above can be sourced and called.
case "${0##*/}" in
  check-content-urls.sh) main "$@" ;;
esac
