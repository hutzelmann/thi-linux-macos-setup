#!/usr/bin/env sh
# Shared helpers. Sourceable without side effects: define, never execute.
#
# Every script here follows the same shape so that tests can source it and call
# individual functions. Nothing runs until main() is called behind a guard.

DRY_RUN=${DRY_RUN:-0}
JSON=${JSON:-0}
REPORT=${REPORT:-0}

log() {
  [ "$JSON" = "1" ] && return 0
  printf '%s\n' "$*"
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

# run <command...>: execute, or print it under --dry-run.
#
# Dry-run output is exactly what the page tells the reader to type, which is
# what makes it testable off-campus: assert the emitted command matches the
# documented one.
run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '  %s\n' "$*"
    return 0
  fi
  "$@"
}

have() {
  command -v "$1" >/dev/null 2>&1
}
