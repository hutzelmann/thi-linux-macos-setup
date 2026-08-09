#!/usr/bin/env sh
#
# fact_env <domain> <key>: print an override from the environment, or fail.
#
# Any documented value can be replaced for one run by setting FACT_<DOMAIN>_<KEY>
# uppercased: FACT_VPN_CA_BUNDLE, FACT_PRINTING_SERVER. Both the repository's
# fact() (scripts/lib/facts.sh) and the generated one in the standalone
# downloads consult this first, so the two behave the same.
#
# This exists so a check can run without changing the machine it documents.
# Verifying the VPN bundle from off campus otherwise means writing to /etc, and
# the container that exercises the print queue has no campus print server to
# point at. The documented value stays the default, so an override is only ever
# visible in the command that set it.
fact_env() {
  # The name is built into an eval below. Keys in facts/*.yaml are [a-z0-9_] by
  # contract (AGENTS.md), so anything else is a caller bug, not a lookup.
  case "$1$2" in
    *[!a-z0-9_]*) return 1 ;;
  esac

  _name=$(printf 'FACT_%s_%s' "$1" "$2" | tr '[:lower:]' '[:upper:]')
  # shellcheck disable=SC2154  # _value is assigned by the eval on the line above
  eval "_value=\${${_name}-}"
  [ -n "$_value" ] || return 1

  printf '%s\n' "$_value"
}

# facts_overridden: the overrides in force, as "domain.key", space separated.
#
# Read back out of the environment rather than recorded as fact_env runs,
# because fact() is almost always called inside a command substitution and a
# variable set in a subshell does not survive it.
#
# Everything that reports a result says what was substituted. A run against a
# replaced value observed something real, but it did not observe what the page
# documents, and the two must not be able to look alike. Splitting at the first
# underscore is exact while every facts/ domain is one word, which is what the
# filenames are.
facts_overridden() {
  env |
    sed -n 's/^FACT_\([A-Z0-9]\{1,\}\)_\([A-Z0-9_]\{1,\}\)=..*/\1.\2/p' |
    tr '[:upper:]' '[:lower:]' |
    sort |
    tr '\n' ' ' |
    sed 's/ *$//'
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
#
# Stamps any environment override into every result, in one place, so no caller
# can produce a result that hides which value it actually used.
json_result() {
  _status="$1"
  _message="$2"
  shift 2
  printf '{"status":"%s","message":"%s"' "$_status" "$_message"
  for _pair in "$@"; do
    printf ',"%s":"%s"' "${_pair%%=*}" "${_pair#*=}"
  done
  _overrides=$(facts_overridden)
  [ -n "$_overrides" ] && printf ',"facts_overridden":"%s"' "$_overrides"
  printf '}\n'
}

# DRY_RUN, JSON and REPORT are declared and read in common.sh; this only sets
# them, which shellcheck cannot see from here.
# shellcheck disable=SC2034
parse_common_args() {
  for _arg in "$@"; do
    case "$_arg" in
      --dry-run) DRY_RUN=1 ;;
      --json) JSON=1 ;;
      --report) REPORT=1 ;;
    esac
  done
}

# Percent-encode one argument.
#
# Hand-rolled because the payload has to survive a URL on a stock macOS shell,
# where there is no jq and no python guaranteed. Slow, and it only ever runs on
# a few hundred characters when somebody asks to file a report.
urlencode() {
  _string="$1"
  while [ -n "$_string" ]; do
    _char=$(printf '%s' "$_string" | cut -c1)
    case "$_char" in
      [a-zA-Z0-9.~_-]) printf '%s' "$_char" ;;
      *) printf '%%%02X' "'$_char" ;;
    esac
    _string=$(printf '%s' "$_string" | cut -c2-)
  done
}

# report_url <page> <outcome> <json>: a check-record form, already filled in.
#
# The reader has followed a page and the script knows almost everything the form
# asks for: which page, which OS, what date, and what it observed. Asking them
# to retype it is how a report stops being worth filing.
#
# Prints only. Nothing is sent, and the contributor sees the whole payload in
# the address bar before deciding to publish it. This repository is public and
# the payload describes their machine, so that order matters.
report_url() {
  _page="$1"
  _outcome="$2"
  _json="$3"
  _repo=$(fact project repo) || return 1

  case "$(detect_os)" in
    arch) _os='Arch Linux' ;;
    debian) _os='Debian / Ubuntu' ;;
    macos) _os='macOS' ;;
    *) _os='Other Linux' ;;
  esac

  printf 'https://github.com/%s/issues/new?template=check-record.yml' "$_repo"
  printf '&labels=check-record'
  printf '&page=%s' "$(urlencode "$_page")"
  printf '&os=%s' "$(urlencode "$_os")"
  printf '&date=%s' "$(urlencode "$(date +%Y-%m-%d)")"
  # Prefilled only on a clean pass. A failing script may mean the page is wrong,
  # or may only mean the reader is off campus, and it cannot tell the two apart.
  [ -n "$_outcome" ] && printf '&outcome=%s' "$(urlencode "$_outcome")"
  printf '&report=%s' "$(urlencode "$_json")"
  printf '\n'
}

# report_outcome <status>: the form's outcome field, or nothing.
#
# Prefilled only on a clean pass. A failing script may mean the page is wrong,
# or may only mean the reader is off campus, and it cannot tell those apart. An
# unset dropdown asks the one question only the person who followed the page can
# answer; a wrong default would be answered by reflex.
#
# An overridden value is the same situation with the doubt made explicit: the
# run passed against a value the page does not document, so it says nothing
# about whether the page works. Never prefill an outcome from one.
report_outcome() {
  [ "$1" = ok ] || return 0
  [ -z "$(facts_overridden)" ] || return 0
  printf 'Worked exactly as written\n'
}

# print_report <page> <outcome> <json>: the closing block of verify.sh --report.
print_report() {
  printf '\n'
  printf 'File this as a check record. Nothing is sent until you press submit:\n\n'
  printf '  %s\n\n' "$(report_url "$1" "$2" "$3")"
  printf 'The form arrives filled in. Correct the outcome if the page misled you.\n'

  _overrides=$(facts_overridden)
  if [ -n "$_overrides" ]; then
    printf '\n'
    printf 'This run replaced documented values from the environment:\n'
    printf '  %s\n' "$_overrides"
    printf 'It checked those, not the ones on the page, so the outcome is left\n'
    printf 'unset and this is not a check record for the page as written.\n'
  fi
}
