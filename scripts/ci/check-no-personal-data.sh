#!/usr/bin/env bash
# Block personal data from entering a public repository.
#
# Patterns only — no names, no allowlist of individuals. A blocklist naming
# people would itself be the leak it is meant to prevent.
#
# Reports about mail, shares and VPN naturally carry usernames, home paths and
# log excerpts. Contributors paste them in good faith; this catches it before it
# reaches a history that cannot be rewritten.
set -euo pipefail

cd "$(dirname "$0")/../.."

fail=0

# Published role addresses are not personal data — they belong to a function,
# not a person, and pointing at the official one is the whole point of R28.
ROLE_ADDRESSES='(support|info|poststelle)(\.[a-z]+)?@(thi|fh-ingolstadt)\.de'

# check <description> <ERE pattern> <hint> [extra pathspec ...]
check() {
  local description="$1" pattern="$2" hint="$3"
  shift 3
  local hits
  if hits=$(git grep -nIE --untracked -- "$pattern" \
      ':!scripts/ci/check-no-personal-data.sh' "$@" 2>/dev/null |
      grep -vE "$ROLE_ADDRESSES"); then
    echo "✗ ${description}"
    echo "$hits" | sed 's/^/  /'
    echo "  fix: ${hint}"
    echo
    fail=1
  fi
}

check "University mail address" \
  '[a-zA-Z0-9._%+-]+@(thi|fh-ingolstadt)\.de' \
  'use <vorname.nachname>@thi.de'

# Placeholders start with '<', so requiring an alphanumeric first character
# distinguishes a real username from /home/<kennung>.
check "Personal home directory" \
  '/(home|Users)/[a-zA-Z0-9][a-zA-Z0-9_-]{2,}' \
  'use /home/<kennung>'

# The domain is a documented value, so it belongs in facts/ — and only there.
check "Windows domain outside facts/" \
  'ESPL_[0-9]+' \
  'reference ${facts.shares.domain} instead' \
  ':!facts/'

check "Inventory sticker number" \
  'IF[0-9]{2}-[0-9]{3}-[0-9]{3}' \
  'use <inventarnummer>'

check "Username in a command flag" \
  '(-U|--user|--username)[= ][a-zA-Z0-9][a-zA-Z0-9_-]{2,}' \
  'use <kennung>' \
  ':!scripts/lib/common.sh'

# Mail archives carry headers, addresses and whole quoted threads.
if archives=$(git ls-files | grep -E '\.(eml|mbox|pst|msg)$' || true); [ -n "$archives" ]; then
  echo "✗ Mail archive tracked in the repository"
  echo "$archives" | sed 's/^/  /'
  echo "  fix: extract the facts, delete the archive"
  echo
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "✓ No personal data found"
fi

exit "$fail"
