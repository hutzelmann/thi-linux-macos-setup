#!/usr/bin/env bash
# Ask whether every URL this project documents still answers.
#
# A vendor moves a driver bundle and a page quietly starts sending people to a
# 404. Nothing on campus changed and no page was edited, so no other check here
# would ever notice.
#
# Only URLs already written down in facts/, one request each, no crawling and no
# guessing at addresses nobody documented.
#
# What counts as an answer, and the exit codes the workflow reads, are in
# lib/url-check.sh, next to the same decision for the addresses in the pages.
# What is here is the list, how a line reads, and what a person does about it.
#
# The runner's own network is worth keeping in mind before reading a run: ci.yml
# already records that a GitHub runner usually cannot reach the campus inside a
# timeout, and the campus-hosted addresses here go unreached together on the
# weeks it cannot.
set -euo pipefail

# $0 is the shell when this file is sourced rather than run, and the guard at
# the foot exists so that it can be. BASH_SOURCE is this file either way.
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

# shellcheck source=lib/url-check.sh
. scripts/ci/lib/url-check.sh

work=

# Every http(s) value in facts/, as `domain.key|url`.
collect() {
  local file domain
  for file in facts/*.yaml; do
    domain=$(basename "$file" .yaml)
    sed -n 's/^\([a-z0-9_]*\):[[:space:]]*\(https\{0,1\}:\/\/[^[:space:]"]*\).*$/\1|\2/p' "$file" |
      sed "s/^/${domain}./"
  done
}

# The values are read from facts/ by both the pages and the checks, so the edit
# is one file and never a page. Addresses that were never reached are named
# again here: the run has something to say and they are not part of it.
report_differs() {
  echo
  echo "An address that stopped answering is an observation, not a fault."
  echo "Find the current one, then update facts/."
  if [ ${#unreached[@]} -gt 0 ]; then
    echo
    echo "Not reached at all on this run, so nothing is claimed about them:"
    printf '  %s\n' "${unreached[@]}"
  fi
}

# Not "all documented URLs answered": a host that declined to answer a script
# did not answer, and this line runs with those present.
report_ok() {
  echo "Every documented address that answered a script answered with a page."
}

main() {
  local key url code reason
  local -a differs=() unreached=()

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT

  while IFS='|' read -r key url; do
    [ -n "$url" ] || continue

    probe "$url"

    case "$(classify "$code")" in
      ok)
        printf '  ok   %-32s %s\n' "$key" "$code"
        ;;
      refused)
        printf '  skip %-32s %s  (refuses automated clients)\n' "$key" "$code"
        ;;
      unreached)
        printf '  ?    %-32s not reached\n' "$key"
        printf '       documented: %s\n' "$url"
        if [ -n "$reason" ]; then
          printf '       %s\n' "$reason"
        fi
        unreached+=("$key")
        ;;
      differs)
        printf '  ✗    %-32s %s\n' "$key" "$code"
        printf '       documented: %s\n' "$url"
        differs+=("$key")
        ;;
    esac
  done < <(collect)

  verdict ${#differs[@]} ${#unreached[@]}
}

# Entry point. Guarded so the functions above can be sourced and called.
case "${0##*/}" in
  check-fact-urls.sh) main "$@" ;;
esac
