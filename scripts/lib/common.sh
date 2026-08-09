#!/usr/bin/env sh
# Shared helpers. Sourceable without side effects: define, never execute.
#
# Every script here follows the same shape so that tests can source it and call
# individual functions. Nothing runs until main() is called behind a guard.

DRY_RUN=${DRY_RUN:-0}
JSON=${JSON:-0}
REPORT=${REPORT:-0}

# Where captured evidence is written, or empty for not capturing any.
# Set by --evidence; see evidence_open below for why this exists at all.
EVIDENCE_DIR=${EVIDENCE_DIR:-}

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

# resolved_addresses <host>: what this machine's resolver answers, verbatim.
#
# Captured as evidence rather than reduced to yes or no, because "the name
# resolves" and "the name resolves to the address it used to" are different
# observations and only the second one catches a server being moved. Four
# implementations because a stock macOS has no getent and a stock Arch has no
# host.
resolved_addresses() {
  if have getent; then
    getent ahosts "$1" 2>/dev/null
  elif have dscacheutil; then
    dscacheutil -q host -a name "$1" 2>/dev/null
  elif have host; then
    host "$1" 2>/dev/null
  else
    nslookup "$1" 2>/dev/null
  fi
}

# --- evidence -----------------------------------------------------------------
#
# A check that prints pass or fail can only be debugged by the person standing
# on the network it failed on. That is the expensive part of this project: the
# campus is a place you have to travel to, and a failure you did not record in
# full is a second trip.
#
# So every check can also write down what it saw: the whole certificate chain,
# not "verifies: no"; the resolved addresses, not "reachable: no"; the printer's
# attributes, not "queue: missing". Those go to files rather than into the JSON
# result, because they are multi-line and because the result is meant to stay
# small enough to paste.
#
# Nothing is uploaded. The directory is left on the machine that made it, and
# the closing note says to read it before it goes anywhere, because it is the
# richest thing this repository can produce about somebody's computer.

# evidence_open <domain>: start a capture directory, if --evidence asked for one.
#
# Called by main() before any observation. A no-op when capture is off, so the
# evidence calls below can stand unguarded in the body of a check.
evidence_open() {
  [ -n "$EVIDENCE_DIR" ] || return 0

  if [ "$EVIDENCE_DIR" = "auto" ]; then
    EVIDENCE_DIR="./evidence-$1-$(date +%Y%m%d-%H%M%S)"
  fi

  mkdir -p "$EVIDENCE_DIR" || die "cannot write to $EVIDENCE_DIR"

  {
    printf 'What this is\n'
    printf '\n'
    printf 'Output captured by %s on %s.\n' "${0##*/}" "$(date +%Y-%m-%d)"
    printf 'Operating system: %s\n' "$(detect_os)"
    _overrides=$(facts_overridden)
    [ -n "$_overrides" ] &&
      printf 'Documented values replaced for this run: %s\n' "$_overrides"
    printf '\n'
    printf 'Usernames, home paths and hardware addresses have been replaced with\n'
    printf 'placeholders. Nothing else has. Read these files before you attach them\n'
    printf 'to anything public: this is a description of your machine, and only you\n'
    printf 'can tell whether some line of it names you.\n'
  } >"$EVIDENCE_DIR/README.txt"
}

# evidence <name>: write stdin to <name>.txt in the capture directory.
#
# Reads stdin either way, so a pipeline into it behaves the same whether or not
# capture is on and a check cannot accidentally block on an unread pipe.
evidence() {
  if [ -z "$EVIDENCE_DIR" ]; then
    cat >/dev/null
    return 0
  fi
  redact >"$EVIDENCE_DIR/$1.txt"
}

# evidence_stream <name>: like evidence, but appends.
#
# For a check that observes the same kind of thing several times over, one file
# per host would be a directory nobody reads. Same file, one block per subject.
evidence_stream() {
  if [ -z "$EVIDENCE_DIR" ]; then
    cat >/dev/null
    return 0
  fi
  redact >>"$EVIDENCE_DIR/$1.txt"
}

# evidence_close: say where it went, once, at the end of a readable run.
evidence_close() {
  [ -n "$EVIDENCE_DIR" ] || return 0
  [ "$JSON" = "1" ] && return 0
  printf '\n'
  printf 'What this run observed is written out in full here:\n'
  printf '  %s\n' "$EVIDENCE_DIR"
  printf 'Read it before attaching it to an issue. It describes your machine.\n'
}
