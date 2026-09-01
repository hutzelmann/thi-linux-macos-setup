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
# Exit codes, because the caller files a public issue from them:
#
#   0  every documented address answered with a page
#   1  an address answered, and what it answered differs from the documentation
#   2  no status was seen, so there is nothing to say
#
# The difference between 1 and 2 is the whole point, and it is the distinction
# check-vpn-chain.sh already draws. A request that never reached a server has
# not seen a status, and filing that as an address that stopped answering is a
# claim about something nobody looked at. The runner's own network is the
# likelier subject: ci.yml already records that a GitHub runner usually cannot
# reach the campus inside the timeout, and the campus-hosted addresses here
# fail together on the weeks it cannot.
set -euo pipefail

cd "$(dirname "$0")/../.."

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

# One request, keeping both halves of what curl says: the status, on stdout,
# and the reason there is no status, on stderr.
#
# The status is read from stdout and never reconstructed from the exit code.
# curl writes its `--write-out` output before exiting non-zero, so the
# `|| echo 000` this used to carry appended a second 000 to a status that
# already said 000. The result was `000000`, which matched no case below and
# was printed into a public issue as though a server had sent it.
probe() {
  code=$(curl -sSL -o /dev/null -w '%{http_code}' --max-time 20 \
    -A 'thi-setup-notes link check' "$1" 2>"$work/reason") || true
  [ -n "$code" ] || code=000
  reason=$(tr -d '\r' <"$work/reason" | tail -n 1)
}

main() {
  local key url code reason
  local -a differs=() unreached=()

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT

  while IFS='|' read -r key url; do
    [ -n "$url" ] || continue

    probe "$url"

    case "$code" in
      2* | 3*)
        printf '  ok   %-32s %s\n' "$key" "$code"
        ;;
      000)
        # No status at all. Printed so the run can be read afterwards, and
        # counted apart from the rest, because nothing was observed here.
        printf '  ?    %-32s not reached\n' "$key"
        printf '       documented: %s\n' "$url"
        if [ -n "$reason" ]; then
          printf '       %s\n' "$reason"
        fi
        unreached+=("$key")
        ;;
      *)
        printf '  ✗    %-32s %s\n' "$key" "$code"
        printf '       documented: %s\n' "$url"
        differs+=("$key")
        ;;
    esac
  done < <(collect)

  if [ ${#differs[@]} -gt 0 ]; then
    echo
    echo "An address that stopped answering is an observation, not a fault."
    echo "Find the current one, then update facts/."
    if [ ${#unreached[@]} -gt 0 ]; then
      echo
      echo "Not reached at all on this run, so nothing is claimed about them:"
      printf '  %s\n' "${unreached[@]}"
    fi
    return 1
  fi

  if [ ${#unreached[@]} -gt 0 ]; then
    echo
    echo "No status was seen for ${#unreached[@]} documented address(es), so nothing was"
    echo "observed about them. That is an account of the network this run had,"
    echo "not of the documentation, and there is nothing to report from it."
    return 2
  fi

  echo "All documented URLs answered."
  return 0
}

# Entry point. Guarded so the functions above can be sourced and called.
case "${0##*/}" in
  check-fact-urls.sh) main "$@" ;;
esac
