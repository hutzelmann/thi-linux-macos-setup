#!/usr/bin/env bash
# Report pages nobody has looked at lately, and pages nobody has looked at.
#
# A check is a statement about a day, not a permanent property. Campus changes
# quietly, so a date from last year is worth less than one from last month, and
# nothing in the repository noticed the difference until this.
#
# The unit is a page and an operating system, not a page. Every page here forks
# its steps three ways and `lastChecked` is a map keyed by the OS the run
# happened on, so a page current on Arch and never touched on macOS has one of
# each rather than an average of the two.
#
# Deliberately not part of `npm run check`. A pull request touching the VPN page
# must not fail because the printing page aged; that trains people to ignore the
# checks. This runs on a schedule and by hand.
set -euo pipefail

cd "$(dirname "$0")/../.."

HORIZON=$(sed -n 's/^stale_after_days:[[:space:]]*//p' facts/project.yaml | head -1)
: "${HORIZON:?stale_after_days missing from facts/project.yaml}"

today=$(date +%s)
stale=0
never=0

stale_list=$(mktemp)
never_list=$(mktemp)
trap 'rm -f "$stale_list" "$never_list"' EXIT

# The operating systems a page declares, one per line. That list is the whole
# scope of what can be checked on it: an OS with no block has no steps to run.
declared_os() {
  sed -n 's/^os:[[:space:]]*\[\(.*\)\]/\1/p' "$1" |
    head -1 |
    tr ',' '\n' |
    tr -d ' "'
}

# The date recorded for one operating system, or nothing.
#
# Reads the indented block under `lastChecked:` and stops at the first line that
# is not an entry, so a following frontmatter key is never mistaken for a date.
recorded_for() {
  awk -v want="$2" '
    /^lastChecked:[[:space:]]*$/ { inblock = 1; next }
    inblock && /^[[:space:]]+[A-Za-z0-9_-]+:/ {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      split(line, parts, ":")
      key = parts[1]
      value = substr(line, index(line, ":") + 1)
      gsub(/[[:space:]"]/, "", value)
      if (key == want) { print substr(value, 1, 10); exit }
      next
    }
    inblock { exit }
  ' "$1"
}

# English pages only. Every page exists in both languages and a check record
# stamps the pair, so walking both would list every page twice and double the
# size of the weekly issue without adding a single work item. A German page that
# has drifted from its source is check-translations.sh's report, not this one.
#
# Pages declare `os` when they have steps to run on a machine. Everything else
# has nothing to check, so counting it as unchecked would invent work.
while IFS= read -r page; do
  grep -q '^os:' "$page" || continue

  # A page written against the old single-date shape would read as unchecked on
  # every OS, which silently understates what somebody actually verified.
  if grep -qE '^lastChecked:[[:space:]]*[^[:space:]]' "$page"; then
    printf '  %s has a scalar lastChecked. It is a map keyed by OS now.\n' "$page"
    continue
  fi

  while IFS= read -r os; do
    [ -n "$os" ] || continue

    recorded=$(recorded_for "$page" "$os")

    if [ -z "$recorded" ]; then
      never=$((never + 1))
      printf '  %-42s %s\n' "$page" "$os" >>"$never_list"
      continue
    fi

    # BSD date and GNU date disagree on everything except -j -f, which GNU lacks.
    if ! seconds=$(date -d "$recorded" +%s 2>/dev/null); then
      seconds=$(date -j -f '%Y-%m-%d' "$recorded" +%s 2>/dev/null) || {
        printf '  %s has an unreadable lastChecked.%s: %s\n' "$page" "$os" "$recorded"
        continue
      }
    fi

    age=$(((today - seconds) / 86400))
    if [ "$age" -gt "$HORIZON" ]; then
      stale=$((stale + 1))
      printf '  %-42s %-7s checked %s, %s days ago\n' \
        "$page" "$os" "$recorded" "$age" >>"$stale_list"
    fi
  done < <(declared_os "$page")
done < <(find content/en -name '*.md' | sort)

echo "Page and OS pairs past ${HORIZON} days: ${stale}"
[ -s "$stale_list" ] && cat "$stale_list"
echo
echo "Page and OS pairs never checked: ${never}"
[ -s "$never_list" ] && cat "$never_list"

# Never a failure. This reports work to be done, and work to be done is the
# normal state of a knowledge base, not a broken build.
exit 0
