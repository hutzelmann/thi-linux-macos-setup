#!/usr/bin/env sh
# Shared helpers. Sourceable without side effects: define, never execute.
#
# Every script here follows the same shape so that tests can source it and call
# individual functions. Nothing runs until main() is called behind a guard.

DRY_RUN=${DRY_RUN:-0}
JSON=${JSON:-0}

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

detect_os() {
  case "$(uname -s)" in
    Darwin) printf 'macos\n' ;;
    Linux)
      if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "${ID:-}${ID_LIKE:-}" in
          *arch*) printf 'arch\n' ;;
          *debian*|*ubuntu*) printf 'debian\n' ;;
          *) printf 'unknown\n' ;;
        esac
      else
        printf 'unknown\n'
      fi
      ;;
    *) printf 'unknown\n' ;;
  esac
}

# Strip anything that identifies a person before results are pasted into a
# public issue. Contributors should not have to remember this.
redact() {
  sed -E \
    -e "s#/home/[^/ ]+#/home/<kennung>#g" \
    -e "s#/Users/[^/ ]+#/Users/<kennung>#g" \
    -e "s#[A-Za-z0-9._%+-]+@(thi|fh-ingolstadt)\.de#<vorname.nachname>@thi.de#g" \
    -e "s#(user|username|-U)[= ][A-Za-z0-9._-]+#\1=<kennung>#g"
}

# json_result <status> <message> [key=value ...]
json_result() {
  _status="$1"
  _message="$2"
  shift 2
  printf '{"status":"%s","message":"%s"' "$_status" "$_message"
  for _pair in "$@"; do
    printf ',"%s":"%s"' "${_pair%%=*}" "${_pair#*=}"
  done
  printf '}\n'
}

parse_common_args() {
  for _arg in "$@"; do
    case "$_arg" in
      --dry-run) DRY_RUN=1 ;;
      --json) JSON=1 ;;
    esac
  done
}
