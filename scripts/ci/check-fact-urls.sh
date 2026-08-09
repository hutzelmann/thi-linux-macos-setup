#!/usr/bin/env bash
# Ask whether every URL this project documents still answers.
#
# A vendor moves a driver bundle and a page quietly starts sending people to a
# 404. Nothing on campus changed and no page was edited, so no other check here
# would ever notice.
#
# Only URLs already written down in facts/, one request each, no crawling and no
# guessing at addresses nobody documented.
set -euo pipefail

cd "$(dirname "$0")/../.."

fail=0

while IFS='|' read -r key url; do
  [ -n "$url" ] || continue

  code=$(curl -sSL -o /dev/null -w '%{http_code}' --max-time 20 -A 'thi-setup-notes link check' "$url" 2>/dev/null || echo 000)

  case "$code" in
    2*|3*) printf '  ok   %-32s %s\n' "$key" "$code" ;;
    000)
      printf '  ✗    %-32s no answer\n' "$key"
      printf '       documented: %s\n' "$url"
      fail=1
      ;;
    *)
      printf '  ✗    %-32s %s\n' "$key" "$code"
      printf '       documented: %s\n' "$url"
      fail=1
      ;;
  esac
done < <(
  for file in facts/*.yaml; do
    domain=$(basename "$file" .yaml)
    sed -n 's/^\([a-z0-9_]*\):[[:space:]]*\(https\{0,1\}:\/\/[^[:space:]"]*\).*$/\1|\2/p' "$file" |
      sed "s/^/${domain}./"
  done
)

if [ "$fail" -eq 0 ]; then
  echo "All documented URLs answered."
else
  echo
  echo "An address that stopped answering is an observation, not a fault."
  echo "Find the current one, then update facts/."
fi

exit "$fail"
